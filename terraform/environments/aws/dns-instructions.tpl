DNS SETUP INSTRUCTIONS FOR ${domain}
========================================

Public IP Address: ${public_ip}

%{ if create_route53_zone }
Route53 Hosted Zone Created
----------------------------

Nameservers for delegation:
%{ for ns in nameservers ~}
  - ${ns}
%{ endfor ~}

ACTION REQUIRED:
1. Go to your domain registrar
2. Update the nameservers for ${domain} to the ones listed above
3. Wait for DNS propagation (typically 15-30 minutes, can be up to 48 hours)

To verify propagation:
  dig NS ${domain}
  dig ${domain}

%{ else }
Manual DNS Configuration
------------------------

Add these records at your DNS provider/registrar:

STEP 1: Basic A Records (Required First)
-----------------------------------------

1. A Record (Root):
   Host:  @
   Value: ${public_ip}
   TTL:   300

2. A Record (Wildcard):
   Host:  *
   Value: ${public_ip}
   TTL:   300

Verification:
  dig ${domain}
  dig test.${domain}

Expected: Both should resolve to ${public_ip}

STEP 2: External Certificate Setup (Optional)
----------------------------------------------

If using Let's Encrypt or another certificate provider:
- Ensure ports 80 and 443 are accessible
- Wait for full DNS propagation
- Follow your certificate provider's instructions

For Let's Encrypt with certbot:
  certbot certonly --standalone -d ${domain} -d *.${domain}

Then copy certificates to the server and update ansible config.

STEP 3: NS Records for Full Burp Functionality (Final Step)
------------------------------------------------------------

After Ansible deployment is complete and Burp Collaborator is running:

3. A Record (NS1):
   Host:  ns1
   Value: ${public_ip}
   TTL:   300

4. NS Record (Self-referencing):
   Host:  @
   Value: ns1.${domain}
   TTL:   300

Note: Some registrars require the A record for ns1 before allowing
      the NS record pointing to it.

Verification:
  dig @${public_ip} test.${domain}
  dig ns1.${domain}

This delegates DNS queries to your Burp Collaborator server,
enabling it to capture DNS-based interactions.

%{ endif }

Summary of Required Steps:
---------------------------
1. Configure A records (@ and *)
2. Wait for DNS propagation (5-30 minutes)
3. Run Ansible deployment
4. Configure NS records (ns1 and @)
5. Verify DNS delegation works

Test DNS propagation:
  https://dnschecker.org/#A/${domain}

Once A records are working, proceed with Ansible:
  cd ../../../ansible
  ansible-playbook -i inventory/aws playbooks/deploy-aws.yml
