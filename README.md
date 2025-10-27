# Private Burp Collaborator with Proxy
This is an AWS Terraform/Ansible deployment of a private Burp Collaborator server with an nginx reverse proxy for "hiding" Burp Collaborator behind a normal-looking website. 

Base domain serves a static site, Burp interaction subdomains get proxied to the backend.

## Why
Burp Collaborator servers are easy to fingerprint just by browsing to a domain that is one. This project aims to make them less obvious by serving a real site on the base domain and only routing Burp-looking subdomains (length pattern) to the collaborator.
This is more of a **template**, not a complete solution. Replace the static site with your own if you want, or use this repo as a starting point for your own more stealthy solution.

## What's Here (for now)
- Terraform for AWS infrastructure
- Ansible for server config
- Nginx reverse proxy with subdomain validation
- Self-signed certs (swap for Let's Encrypt)
- Generic static site (replace this)

## Quick Start
For the quickest start, you can fill out your variables for terraform and ansible, then run the magic script.

Other than the ones that you have to change, you can leave everything else as-is. However, depending on how old this repo is at the time of reading, you may need to change some things.

```bash
# Configure terraform and ansible variables
cp terraform/environments/aws/terraform.tfvars.example terraform/environments/aws/terraform.tfvars
vim terraform/environments/aws/terraform.tfvars
vim ansible/group_vars/aws.yml

# Deploy and follow the prompts
./scripts/deploy_aws.sh
```


## DNS Setup

**Before Ansible:**
- Add A records: `@` and `*` → server IP
- Wait for propagation

**After deployment:**
- Add A record: `ns1` → server IP
- Add NS record: `@` → `ns1.yourdomain.com`

## Customize the Cover Site (Optional)
You would probably want to do this step before deployment. However, you can do it after deployment if you want.
Depending on what kind of setup you want, you will also want to edit the nginx site config.

```bash
# Before deployment
rm -rf static-site/*
cp -r /path/to/your/site/* static-site/

# After deployment
scp -r /path/to/your/site/* ubuntu@<server-ip>:/var/www/burp-cover/
ssh ubuntu@<server-ip> 'sudo systemctl restart nginx'
```

## How Routing Works
- `yourdomain.com` → Your static site
- `polling.yourdomain.com` → Burp polling
- `g84735gh6758gh47858734gh7gfbav45h.yourdomain.com` → Burp (matches pattern)
- `api.yourdomain.com` → Your static site (doesn't match)

Edit `ansible/roles/nginx-proxy/templates/burp-site.conf.j2` to change this.

## Let's Encrypt Cert Setup
You probably wouldn't want to use self-signed certs. This is an example of how to get Let's Encrypt certs rolling after deployment.

```bash
# On server
sudo certbot certonly --manual --preferred-challenges dns-01 -d yourdomain.com -d *.yourdomain.com

# Verify TXT records
dig txt _acme-challenge.yourdomain.com

# Copy certs
sudo cp /etc/letsencrypt/archive/yourdomain.com/fullchain1.pem /etc/ssl/burp/burp-cert.pem
sudo cp /etc/letsencrypt/archive/yourdomain.com/privkey1.pem /etc/ssl/burp/burp-key.pem
sudo chown root:burp /etc/ssl/burp/*.pem
sudo chmod 644 /etc/ssl/burp/burp-cert.pem
sudo chmod 640 /etc/ssl/burp/burp-key.pem
sudo systemctl restart burp-collaborator nginx
```

## Burp Suite Config
Settings → Project → Collaborator:
- Server location: `yourdomain.com`
- Polling location: `polling.yourdomain.com`

Run a health check to make sure everything is mostly working.

## Testing
```bash
dig @<server-ip> test.yourdomain.com
curl https://yourdomain.com                # Should show static site
curl https://g84735gh6758gh47858734gh7gfbav45h.yourdomain.com       # Should be proxied to Burp
```

## Ideas for Improvement
These can be for the overachieving individuals out there.

- Replace static HTML with a real app (Flask, Express, etc.)
- Add legitimate API endpoints
- Use different content based on headers
- Serve a WordPress login page that always fails :)


## Disclaimer
This project is a template that makes the Burp Collaborator server less obvious on the internet (to random people/crawlers). Any collaborator payloads used will still point defenders to this being a Burp Collaborator server.

Use ethically, follow the law, and I'm not responsible for what you do with it.
