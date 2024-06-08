`ansible reck -m authorized_key -a "user=root exclusive=true manage_dir=true key='$(< /home/codespace/.ssh/id_rsa.pub)'" -k`

安装代理
https://github.com/mzz2017/gg/blob/main/README_zh.md
设置代理
`gg config -w subscription=https://xn--5hqx9equq.com/api/v1/client/subscribe?token=e87ad20e1f17567da8b216b5d4543109`
安装语法检查器
`pip install ansible-lint`

检查ansible 环境以及远程kvm连接
`ansible-playbook playbooks.yaml -vvv --tags hello`

执行 playbook
`ansible-playbook playbooks.yaml -v ` // 显示详细log -vv -vvv
                                                                                                    
`apt updte`

`apt-get -y --force-yes install curl`

`cd ansible`

`ansible-playbook playbooks.yaml -v# ansible`



```bash

chmod u+x,g-wx,o-wx ansible

$ git config --global user.name "lvhongyuan"  #名称
$ git config --global user.email v2vvcn@gmail.com   #邮箱
```


将公钥添加到kvm中
`ansible-playbook playbooks.yaml -v --tags authorized`

warn dangrous
添加私钥到 cosdspace /root/.ssh 

`cp /workspaces/ansible/config/.ssh/id_rsa /root/.ssh && chmod 600 /root/.ssh/id_rsa `

安装 docker
`ansible-playbook playbooks.yaml -vv --tags installdocker`

roles 安装 vscodetunnel

`ansible-playbook playbooks.yaml -vv --tags vscodetunnel`

# cosdspace 调试

1. 项目根目录创建 hosts文件
```ini
default ansible_ssh_host=127.0.0.1 ansible_ssh_user="root" ansible_ssh_pass=changepassword ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
```

2. 执行测试命令

```bash
ansible-playbook -i hosts  playbooks.yaml -vvv --tags hello
ansible-playbook -i hosts  playbooks.yaml -vv --tags hello
```

3. 使用命令行变量

```bash
ansible-playbook -i hosts  playbooks.yaml -vv --tags install_semaphore --extra-vars "password=changeme"
ansible-playbook -i hosts  playbooks.yaml -vv --tags install_ddns-go --extra-vars "ddns-go_pwd=changeme cloudfare_token=token"
```
4. 指定主机命令
```shell
# 默认主机
ansible-playbook -i hosts -e "host=default" playbooks.yaml -vvv --tags hello
ansible-playbook -i hosts -e "host=default" playbooks.yaml -vv --tags hello
# 本地主机
ansible-playbook -i hosts -e "host=default" playbooks.yaml -vvv --tags hello
ansible-playbook -i hosts -e "host=default" playbooks.yaml -vv --tags hello
```