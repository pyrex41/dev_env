# Google Cloud Billing Setup Guide

## Why Billing is Required

Google Kubernetes Engine (GKE) is a paid service that requires an active billing account. However:

- **New users get $300 free credits** valid for 90 days
- You won't be charged until the credits expire
- You can set up billing alerts to avoid unexpected charges
- You can delete resources anytime to stop charges

## Estimated Costs

For this demo project:
- **Small GKE cluster**: ~$75/month (1 node e2-standard-2)
- **With $300 credits**: You can run this for 3-4 months free
- **Remember**: Delete the cluster when done to stop charges

## Step-by-Step Billing Setup

### Method 1: Web Console (Easiest)

1. **Open Google Cloud Console Billing**
   ```
   https://console.cloud.google.com/billing
   ```

2. **Create Billing Account**
   - Click "Create Account" or "Link a billing account"
   - Choose "Individual" or "Business"
   - Fill in your information
   - Add payment method (credit card required)
   - **Note**: You won't be charged until free credits expire

3. **Link to Your Project**
   - Select "My Projects" from the left menu
   - Find your project (ID: your-project-id)
   - Click the three dots (⋮) → "Change billing"
   - Select your billing account
   - Click "Set account"

4. **Verify Billing is Enabled**
   ```bash
   gcloud beta billing projects describe YOUR_PROJECT_ID
   ```
   Should show: `billingEnabled: true`

5. **Continue with GKE Setup**
   ```bash
   make gke-setup
   ```

### Method 2: Command Line

1. **List Available Billing Accounts**
   ```bash
   gcloud alpha billing accounts list
   ```

2. **Create Billing Account (if needed)**
   - Must be done through web console
   - Visit: https://console.cloud.google.com/billing

3. **Link Billing Account to Project**
   ```bash
   gcloud beta billing projects link YOUR_PROJECT_ID \
     --billing-account=BILLING_ACCOUNT_ID
   ```

4. **Verify**
   ```bash
   gcloud beta billing projects describe YOUR_PROJECT_ID
   ```

## Setting Up Billing Alerts

**Recommended**: Set up alerts to avoid surprise charges

1. Visit https://console.cloud.google.com/billing
2. Select your billing account
3. Click "Budgets & alerts" in left menu
4. Click "Create Budget"
5. Set budget to $50 or $100
6. Set alerts at 50%, 75%, and 90%
7. You'll receive email notifications

## Cost Control Best Practices

### 1. Always Delete Resources When Done
```bash
# Delete GKE cluster (stops charges)
make gke-teardown

# Or manually:
gcloud container clusters delete wander-cluster --zone us-central1-a
```

### 2. Use Smallest Machine Types
```bash
# Our default: e2-standard-2 (~$75/month)
# Cheaper option: e2-micro (~$10/month, limited resources)
```

### 3. Auto-Delete After Development
Set up a reminder or use gcloud to auto-delete:
```bash
# Schedule cluster deletion
gcloud container clusters create wander-cluster \
  --zone us-central1-a \
  --enable-autoscaling \
  --num-nodes 1 \
  --max-nodes 1
```

### 4. Monitor Usage
```bash
# Check current usage
gcloud billing projects describe YOUR_PROJECT_ID

# View billing in console
open https://console.cloud.google.com/billing
```

## Free Tier vs Paid Resources

**Free Tier (Always Free)**:
- Cloud Functions (2M invocations/month)
- Cloud Run (2M requests/month)
- Firestore (1 GB storage)
- Cloud Storage (5 GB)

**GKE (Paid Service)**:
- Cluster management: $0.10/hour (~$75/month)
- Compute resources: Based on machine type
- Network egress: Based on traffic
- **NOT covered by always-free tier**
- **IS covered by $300 credits**

## What If I Don't Want to Enable Billing?

### Alternative: Use Local Kubernetes (Minikube)

Completely free, runs on your machine:

```bash
# Install Minikube
brew install minikube

# Setup and deploy
make k8s-setup
make k8s-deploy

# Access via port forwarding
kubectl port-forward -n wander svc/wander-frontend 3000:3000
```

### Alternative: Use Docker Compose

Even simpler, no Kubernetes needed:

```bash
# Already working in this project!
make dev
```

## Troubleshooting

### "Billing account not found"
- Make sure you created a billing account at console.cloud.google.com/billing
- Verify the billing account is active
- Check that it's linked to your project

### "Credit card declined"
- Google may require a valid credit card even for free credits
- Try a different card
- Contact Google Cloud support

### "Project doesn't have billing enabled"
```bash
# Check billing status
gcloud beta billing projects describe YOUR_PROJECT_ID

# If false, link billing account
gcloud beta billing projects link YOUR_PROJECT_ID \
  --billing-account=BILLING_ACCOUNT_ID
```

## Summary

1. Visit https://console.cloud.google.com/billing
2. Create billing account (requires credit card)
3. Link to project
4. Get $300 free credits (90 days)
5. Set up billing alerts
6. **Remember to delete resources when done!**

---

**Next steps after billing is enabled:**
```bash
make gke-setup
```
