`ansible reck -m authorized_key -a "user=root exclusive=true manage_dir=true key='$(< /home/codespace/.ssh/id_rsa.pub)'" -k`

安装代理
https://github.com/mzz2017/gg/blob/main/README_zh.md
设置代理
`gg config -w subscription=https://xn--5hqx9equq.com/api/v1/client/subscribe?token=e87ad20e1f17567da8b216b5d4543109`
安装语法检查器
`pip install ansible-lint`
执行 playbook
`ansible-playbook playbooks.yaml -v ` // 显示详细log -vv -vvv
                                                                                                    
`apt updte`

`apt-get -y --force-yes install curl`

`cd ansible`

`ansible-playbook playbooks.yaml -v# ansible`

chmod u+x,g-wx,o-wx ansible

$ git config --global user.name "lvhongyuan"  #名称
$ git config --global user.email v2vvcn@gmail.com   #邮箱



将公钥添加到kvm中
`ansible-playbook playbooks.yaml -v --tags authorized`

warn dangrous
添加私钥到 cosdspace /root/.ssh 

`cp /workspaces/ansible/files/.ssh/id_rsa /root/.ssh && chmod 600 /root/.ssh/id_rsa `

