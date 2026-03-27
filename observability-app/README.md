# OpenTelemetry Observability Stack Deployment

This folder contains the complete Application Docker deployment for your OpenTelemetry ecosystem.
Because it is completely decoupled from your Terraform infrastructure pipeline, you control exactly when and how these containers are updated.

To deploy this observability stack to your Google Cloud VM manually, follow these 3 steps:

### 1. Copy these files to the VM
Open your terminal on your laptop and securely copy this entire `config` folder over to the VM:
```bash
gcloud compute scp --recurse . dev-otel-gateway:~/config --project=infra-test-491414 --zone=asia-southeast1-a
```

### 2. SSH into the VM
Connect to the VM to run the deployment:
```bash
gcloud compute ssh dev-otel-gateway --project=infra-test-491414 --zone=asia-southeast1-a
```

### 3. Start the Application
Inside the VM, move into the folder and start `docker-compose`:
```bash
cd ~/config

# Container-Optimized OS requires you to run docker-compose using the official docker image
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.29.2 up -d
```

### Verification
Once it boots, your dashboard will instantly be available privately on your laptop via Tailscale at:
`http://grafana.araiwadev.local:3000`
