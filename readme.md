`ansible reck -m authorized_key -a "user=root exclusive=true manage_dir=true key='$(< /home/codespace/.ssh/id_rsa.pub)'" -k`


`ansible-playbook playbooks.yaml -v ` 

apt updte

apt-get -y --force-yes install curl

cd ansible

ansible-playbook playbooks.yaml -v# ansible
