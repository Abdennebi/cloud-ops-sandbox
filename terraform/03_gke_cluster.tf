# Let's create the GKE cluster! This one's pretty complicated so buckle up.

# This is another example of the random provider. Here we're using it to pick a
# zone in us-central1 at random.
resource "random_shuffle" "zone" {
  input = ["us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f"]

  # Seeding the RNG is technically optional but while I was building this I
  # found that it only ever picked `us-central-1c` unless I seeded it. Here
  # we're using the ID of the project as a seed because it is unique to the
  # project but will not change, thereby guaranteeing stability of the results.
  seed = "${google_project.project.id}"
}

# First we create the cluster. If you're wondering where all the sizing details
# are, they're below in the `google_container_node_pool` resource. We'll get
# back to that in a minute.
#
# One thing to note here is the name of the resource ("gke") is only used
# internally, for instance when you're referencing the resource (eg
# `google_container_cluster.gke.id`). The actual created resource won't know
# about it, and in fact you can specify the name for that in the resource
# itself.
#
# Finally, there are many, many other options available. The resource below
# replicates what the Hipster Shop README creates. If you want to see what else
# is possible, check out the docs: https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "gke" {
  project = "${google_project.project.id}"

  # ... and here's how you specify the name
  name = "stackdriver-sandbox"

  # next we set the zone by grabbing the result of the random_shuffle above. It
  # returns a list so we have to pull the first element off. If you're looking
  # at this and thinking "huh terraform syntax looks a clunky" you are NOT WRONG
  zone = "${element(random_shuffle.zone.result, 0)}"

  # here we're using an embedded resource to define the node pool. Another
  # option would be to create the node pool as a separate resource and link it
  # to this cluster. There are tradeoffs to each approach.
  #
  # The embedded resource is convenient but if you change it you have to tear
  # down the entire cluster and rebuild it. A separate resource could be
  # modified independent of the cluster without the cluster needing to be torn
  # down.
  #
  # For this particular case we're not going to be modifying the node pool once
  # it's deployed, so it makes sense to accept the tradeoff for the convenience
  # of having it inline.
  #
  # Many of the paramaters below are self-explanatory so I'll only call out
  # interesting things.
  node_pool {
    node_config {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"  
      ]

      labels = {
        environment = "dev",
        cluster = "stackdriver-sandbox-main"   
      }
    }
    
    initial_node_count = 5

    # this stanza could be left off and we'd just always have five nodes
    autoscaling {
      min_node_count = 3
      max_node_count = 10
    }

    # this stanza could be omitted and both would default to false
    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }

  # Stores the zone of created gke cluster
  provisioner "local-exec" {
    command = "echo ${element(random_shuffle.zone.result, 0)} >>sandbox.txt"
  }
  
  # add a hint that the service resource must be created (i.e., the service must
  # be enabled) before the cluster can be created. This will not address the
  # eventual consistency problems we have with the API but it will make sure
  # that we're at least trying to do things in the right order.
  depends_on = ["google_project_service.gke"]
}

# Customize kubernetes manifests for upcoming deployment to GKE
resource "null_resource" "customize_manifests" {
  provisioner "local-exec" {
    command = "./customize-manifests.sh"
  }
}

# Set current project 
resource "null_resource" "current_project" {
  provisioner "local-exec" {
    command = "gcloud config set project ${google_project.project.id}"
  }

  depends_on = ["null_resource.customize_manifests"]
}

# Setting kubectl context to currently deployed GKE cluster
resource "null_resource" "set_gke_context" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials stackdriver-sandbox --zone ${element(random_shuffle.zone.result, 0)} --project ${google_project.project.id}"
  }

  depends_on = [
    "google_project_service.gke", 
    "null_resource.customize_manifests",
    "null_resource.current_project"
  ]
}

# Deploy microservices into GKE cluster 
resource "null_resource" "deploy_services" {
  provisioner "local-exec" {
    command = "kubectl apply -f ..//release//kubernetes-manifests.yaml"
  }

  depends_on = ["null_resource.set_gke_context"]
}

# There is no reliable way to do deployment verification with kubernetes
# For the purposes of Sandbox, we can mitigate by waiting a few sec to ensure kubectl apply completes
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }
  triggers = {
    "before" = "${null_resource.deploy_services.id}"
  }
}

