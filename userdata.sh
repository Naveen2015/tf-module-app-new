#!/bin/bash
labauto ansible
ansible-pull -i localhost, -U https://github.com/Naveen2015/roboshop-ansible-new.git roboshop.yml -e role_name=${name} -e env=${env} &>> /opt/ansible.log
