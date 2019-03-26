# Stackdriver Sandbox (Alpha)
Stackdriver Sandbox is an open source tool that helps practitioners to learn Service Reliability Engineering practices from Google and apply them on their cloud services using Stackdriver. It is based on [Hipster Shop](https://github.com/GoogleCloudPlatform/microservices-demo) - Cloud-Native Microservices Demo Application.

It offers:

* **Demo Service** - an application built using microservices architecture on modern, cloud native stack.
* **One-click deployment script** of the service to Google Cloud Platform
* **Load Generator** - a component that produces synthetic traffic on a demo service
* (Soon) **SRE Runbook** - pre-built routine procedures  for  operating deployed sample service that follows best SRE practices using Stackdriver

## Why Sandbox

Google Stackdriver is a suite of tools that helps to gain full observability for your code and applications. You might want to take Stackdriver to a "test drive" in order to answer a question: "Will it work for my application needs"? The most effective way to learn is by testing the tool in "real-life" conditions, but without risking production. With Sandbox we provide a tool that automatically provisions a new demo cluster that receives traffic, simulating real users. Practicioners can try out using various Stackdriver tools to solve problems and accomplish standard SRE taks on a Sandboxed environment.

## Getting Started

* Creating new Sandbox
  * [Prerequisites](#Prerequisites)
  * [Setup](#Setup)
* [Service Overview](#Service-Overview)
  * [Screenshots](#Screenshots)
  * [Architecture](#Architecture)
* Contribute code to Sandbox
  * [Running locally](#Running-locally)
  * [Running on GKE](#Running-on-GKE)
  * [Using static images](#Using-static-images)
  * [GKE with Istio](#GKE-with-Istio)

## Creating new Sandbox

### Prerequisites

* Create and enable [Cloud Billing Account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

### Setup

1. Click the Cloud Shell button for automated one click installation of a new Stackdriver Sandbox cluster in a new Google Cloud Project.

[![Open in Cloud Shell](//gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://source.developers.google.com/p/stackdriver-sandbox-230822/r/sandbox&cloudshell_git_branch=master&cloudshell_working_dir=terraform)

2. In the Cloud Shell command prompt, type:

```bash
$ ./install.sh
```

### Next Steps

* Explore your Sandbox deployment and its [architecture](#Service-Overview)
* Learn more about Stackdriver using [Code Labs](https://codelabs.developers.google.com/gcp-next/?cat=Monitoring)

## Service Overview

This project contains a 10-tier microservices application. It is a
web-based e-commerce app called **“Hipster Shop”** where users can browse items,
add them to the cart, and purchase them.

### Screenshots

| Home Page | Checkout Screen |
|-----------|-----------------|
| [![Screenshot of store homepage](./docs/img/hipster-shop-frontend-1.png)](./docs/img/hipster-shop-frontend-1.png) | [![Screenshot of checkout screen](./docs/img/hipster-shop-frontend-2.png)](./docs/img/hipster-shop-frontend-2.png) |

### Service Architecture

**Hipster Shop** is composed of many microservices written in different languages that talk to each other over gRPC.
>**We are not endorsing the architecture of Hipster Shop as the best way to build such a shop!**
> The architecture is optimized for learning purposes and includes modern stack: Kubernetes, GKE, Istio,
Stackdriver, gRPC, OpenCensus** and similar cloud-native technologies.

[![Architecture of
microservices](./docs/img/architecture-diagram.png)](./docs/img/architecture-diagram.png)

Find **Protocol Buffers Descriptions** at the [`./pb` directory](./pb).

| Service | Language | Description |
|---------|----------|-------------|
| [frontend](./src/frontend) | Go | Exposes an HTTP server to serve the website. Does not require signup/login and generates session IDs for all users automatically. |
| [cartservice](./src/cartservice) |  C# | Stores the items in the user's shipping cart in Redis and retrieves it. |
| [productcatalogservice](./src/productcatalogservice) | Go | Provides the list of products from a JSON file and ability to search products and get individual products. |
| [currencyservice](./src/currencyservice) | Node.js | Converts one money amount to another currency.  Uses real values fetched from European Central Bank. It's the highest QPS service. |
| [paymentservice](./src/paymentservice) | Node.js | Charges the given credit card info (hypothetically😇) with the given amount and returns a transaction ID. |
| [shippingservice](./src/shippingservice) | Go | Gives shipping cost estimates based on the shopping cart. Ships items to the given address (hypothetically😇) |
| [emailservice](./src/emailservice) | Python | Sends users an order confirmation email (hypothetically😇). |
| [checkoutservice](./src/checkoutservice) | Go | Retrieves user cart, prepares order and orchestrates the payment, shipping and the email notification. |
| [recommendationservice](./src/recommendationservice) | Python | Recommends other products based on what's given in the cart. |
| [adservice](./src/adservice) | Java | Provides text ads based on given context words. |
| [loadgenerator](./src/loadgenerator) | Python/Locust | Continuously sends requests imitating realistic user shopping flows to the frontend. |

### Technologies

* **[Kubernetes](https://kubernetes.io)/[GKE](https://cloud.google.com/kubernetes-engine/):**
  The app is designed to run on Google Kubernetes Engine.
* **[gRPC](https://grpc.io):** Microservices use a high volume of gRPC calls to
  communicate to each other.
* **[OpenCensus](https://opencensus.io/) Tracing:** Most services are
  instrumented using OpenCensus trace interceptors for gRPC/HTTP.
* **[Stackdriver APM](https://cloud.google.com/stackdriver/):** Many services
  are instrumented with **Profiling**, **Tracing** and **Debugging**.
  **Metrics** and **Context Graph** out of the box.
* **[Skaffold](https://github.com/GoogleContainerTools/skaffold):** A tool used for doing repeatable deployments. You can deploy to Kubernetes with a single command using Skaffold.
* **Synthetic Load Generation:** The application demo comes with dedicated load generation service thatthat creates realistic usage patterns on Hipster Shop website using
  [Locust](https://locust.io/) load generator.

## For Developers

> **Note:** that the first build can take up to 20-30 minutes. Consequent builds
> will be faster.

### Option 1: Running locally with “Docker for Desktop”

> 💡 Recommended if you're planning to develop the application.

1. Install tools to run a Kubernetes cluster locally:

   - kubectl (can be installed via `gcloud components install kubectl`)
   - Docker for Desktop (Mac/Windows): It provides Kubernetes support as [noted
     here](https://docs.docker.com/docker-for-mac/kubernetes/).
   - [skaffold](https://github.com/GoogleContainerTools/skaffold/#installation)
     (ensure version ≥v0.20)

1. Launch “Docker for Desktop”. Go to Preferences:
   - choose “Enable Kubernetes”,
   - set CPUs to at least 3, and Memory to at least 6.0 GiB

3. Run `kubectl get nodes` to verify you're connected to “Kubernetes on Docker”.

4. Run `skaffold run` (first time will be slow, it can take ~20-30 minutes).
   This will build and deploy the application. If you need to rebuild the images
   automatically as you refactor he code, run `skaffold dev` command.

5. Run `kubectl get pods` to verify the Pods are ready and running. The
   application frontend should be available at http://localhost:80 on your
   machine.

### Option 2: Running on Google Kubernetes Engine (GKE)

> 💡  Recommended for demos and making it available publicly.

1. Install tools specified in the previous section (Docker, kubectl, skaffold)

1. Create a Google Kubernetes Engine cluster and make sure `kubectl` is pointing
   to the cluster.

        gcloud services enable container.googleapis.com

        gcloud container clusters create demo --enable-autoupgrade \
            --enable-autoscaling --min-nodes=3 --max-nodes=10 --num-nodes=5 --zone=us-central1-a

        kubectl get nodes

1. Enable Google Container Registry (GCR) on your GCP project and configure the
   `docker` CLI to authenticate to GCR:

       gcloud services enable containerregistry.googleapis.com

       gcloud auth configure-docker -q

1. In the root of this repository, run `skaffold run --default-repo=gcr.io/[PROJECT_ID]`,
   where [PROJECT_ID] is your GCP project ID.

   This command:
   - builds the container images
   - pushes them to GCR
   - applies the `./kubernetes-manifests` deploying the application to
     Kubernetes.

   **Troubleshooting:** If you get "No space left on device" error on Google
   Cloud Shell, you can build the images on Google Cloud Build: [Enable the
   Cloud Build
   API](https://console.cloud.google.com/flows/enableapi?apiid=cloudbuild.googleapis.com),
   then run `skaffold run -p gcb  --default-repo=gcr.io/[PROJECT_ID]` instead.

1.  Find the IP address of your application, then visit the application on your
    browser to confirm installation.

        kubectl get service frontend-external

    **Troubleshooting:** A Kubernetes bug (will be fixed in 1.12) combined with
    a Skaffold [bug](https://github.com/GoogleContainerTools/skaffold/issues/887)
    causes load balancer to not to work even after getting an IP address. If you
    are seeing this, run `kubectl get service frontend-external -o=yaml | kubectl apply -f-`
    to trigger load balancer reconfiguration.

### Option 3: Using Static Images 

> 💡 Recommended for test-driving the application on an existing cluster. 

**Prerequisite**: a running Kubernetes cluster. 

1. Clone this repository.
1. Deploy the application: `kubectl apply -f ./release/kubernetes-manifests`  
1. Run `kubectl get pods` to see pods are in a healthy and ready state.
1.  Find the IP address of your application, then visit the application on your
    browser to confirm installation.

        kubectl get service frontend-external

### Generate Synthetic Traffic

1. If you want to create synthetic load manually, in the root of the repository, use the `loadgenerator-tool` executable. For example:

```bash
$ ./loadgenerator-tool startup --zone us-central1-c [SANDBOX_FRONTEND_ADDRESS]
```

### (Optional) Deploying on a Istio-installed GKE cluster

> **Note:** you followed GKE deployment steps above, run `skaffold delete` first
> to delete what's deployed.

1. Create a GKE cluster (described above).

2. Use [Istio on GKE add-on](https://cloud.google.com/istio/docs/istio-on-gke/installing)
   to install Istio to your existing GKE cluster.

       gcloud beta container clusters update demo \
           --zone=us-central1-a \
           --update-addons=Istio=ENABLED \
           --istio-config=auth=MTLS_PERMISSIVE

   > NOTE: If you need to enable `MTLS_STRICT` mode, you will need to update
   > several manifest files:
   >
   > - `kubernetes-manifests/frontend.yaml`: delete "livenessProbe" and
   >   "readinessProbe" fields.
   > - `kubernetes-manifests/loadgenerator.yaml`: delete "initContainers" field.

3. (Optional) Enable Stackdriver Tracing/Logging with Istio Stackdriver Adapter
   by [following this guide](https://cloud.google.com/istio/docs/istio-on-gke/installing#enabling_tracing_and_logging).

4. Install the automatic sidecar injection (annotate the `default` namespace
   with the label):

       kubectl label namespace default istio-injection=enabled

5. Apply the manifests in [`./istio-manifests`](./istio-manifests) directory.

       kubectl apply -f ./istio-manifests

    This is required only once.

6. Deploy the application with `skaffold run --default-repo=gcr.io/[PROJECT_ID]`.

7. Run `kubectl get pods` to see pods are in a healthy and ready state.

8. Find the IP address of your istio gateway Ingress or Service, and visit the
   application.

       INGRESS_HOST="$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

       echo "$INGRESS_HOST"

       curl -v "http://$INGRESS_HOST"

---

This is not an official Google project.
