.PHONY: k3s argocd nginx-ingress falco all

k3s:
	ansible-playbook -i inventory.yml playbooks/k3s.yml

argocd:
	ansible-playbook -i inventory.yml playbooks/argocd.yml

nginx-ingress:
	ansible-playbook -i inventory.yml playbooks/nginx-ingress.yml

falco:
	ansible-playbook -i inventory.yml playbooks/falco.yml

all:
	$(MAKE) k3s
	$(MAKE) argocd
	$(MAKE) nginx-ingress
	$(MAKE) falco
