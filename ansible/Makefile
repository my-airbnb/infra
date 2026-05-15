.PHONY: k3s sealed-secrets argocd nginx-ingress falco all

k3s:
	ansible-playbook -i inventory.yml playbooks/k3s.yml

sealed-secrets:
	ansible-playbook -i inventory.yml playbooks/sealed-secrets.yml

argocd:
	ansible-playbook -i inventory.yml playbooks/argocd.yml

nginx-ingress:
	ansible-playbook -i inventory.yml playbooks/nginx-ingress.yml

falco:
	ansible-playbook -i inventory.yml playbooks/falco.yml

all:
	$(MAKE) k3s
	$(MAKE) sealed-secrets
	$(MAKE) argocd
	$(MAKE) nginx-ingress
	$(MAKE) falco
