.PHONY: k3s sealed-secrets nginx-ingress cert-manager argocd argocd-app falco all

k3s:
	ansible-playbook -i inventory.yml playbooks/k3s.yml

sealed-secrets:
	ansible-playbook -i inventory.yml playbooks/sealed-secrets.yml

nginx-ingress:
	ansible-playbook -i inventory.yml playbooks/nginx-ingress.yml

cert-manager:
	ansible-playbook -i inventory.yml playbooks/cert-manager.yml

argocd:
	ansible-playbook -i inventory.yml playbooks/argocd.yml

argocd-app:
	ansible-playbook -i inventory.yml playbooks/argocd-app.yml

falco:
	ansible-playbook -i inventory.yml playbooks/falco.yml

all:
	$(MAKE) k3s
	$(MAKE) sealed-secrets
	$(MAKE) nginx-ingress
	$(MAKE) cert-manager
	$(MAKE) argocd
	$(MAKE) argocd-app
	$(MAKE) falco
