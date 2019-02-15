# Here we are creating a project to contain the deployed resources. A couple of
# general terraform notes: this is the first time we're seeing the `data`
# stanza. This gives a way to look stuff up and use it in other resources. Here
# we're looking up the billing account by name (hence why the README has you
# name it a certain way) so we can pass its ID on later.
#
# If productized we'd drop this and use the default billing account instead.
data "google_billing_account" "acct" {
  display_name = "Google"
}

# This generates a random project id that starts with "stackdriver-sandbox-" and
# ends with a random number in the unsigned int range. See the docs for more:
# https://www.terraform.io/docs/providers/random/r/id.html
resource "random_id" "project" {
  prefix = "stackdriver-sandbox-"
  byte_length = "4"
}

# Here we create the actual project.
resource "google_project" "project" {
  name = "Hipster Shop Terraform Demo"

  # This references the random project ID we created above; note that we're
  # asking for the `dec` attribute which returns the number in decimal format
  project_id = "${random_id.project.dec}"

  # This references the billing account that we looked up before. Note the
  # `data.` prefix vs. using the resource name directly as we did above with
  # `random_id.`
  billing_account = "${data.google_billing_account.acct.id}"
}

# This enables GKE in the project we just created. There's also the
# `google_project_service` resource which can be used to enable a single
# service, but most of the time you want to use this one so it's easier to
# expand the list later.
resource "google_project_services" "gke" {
  # This could just as easily reference `random_id.project.dec` but generally
  # you want to dereference the actual object you're trying to interact with.
  #
  # You'll see this line in every resource we create from here on out. This is
  # necessary because we didn't configure the provider with a project because
  # the project didn't exist yet. This could be refactored such that the project
  # was created outside of terraform, the provider configured with the project,
  # and then we don't have to specify this on every resource any more.
  #
  # Anyway, expect to see a lot more of these. I won't explain every time.
  project = "${google_project.project.id}"

  # a list of the service URIs we want to enable
  services = [
    "container.googleapis.com"
  ]
}
