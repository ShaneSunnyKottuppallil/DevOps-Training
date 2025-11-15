# 🚀 ChatApp Ansible Deployment — Full Infrastructure Automation Documentation

This repository provides a complete **Infrastructure-as-Code (IaC)** implementation using **Ansible** to deploy a **three-tier chat application** consisting of:

- 🗄️ **MySQL Database** (`chatdb`)
- 🐍 **Django Application** served via Gunicorn (`chatapp`)
- 🌐 **Nginx Reverse Proxy** (`chatweb`)

The repository includes **inventories, roles, templates, handlers, and playbooks** that automate provisioning, configuration, deployment, and service orchestration.

---

# 📌 1. Project Summary

This project deploys a simple three-tier chat application using Ansible:  
a MySQL database (`chatdb`), a Django application (`chatapp`) served by Gunicorn, and an Nginx reverse-proxy (`chatweb`).  

The repo contains inventories, playbooks, and three roles that together:

- Provision packages  
- Install/configure services  
- Deploy application code  
- Create databases/users  
- Wire application to database  

---

# 📄 2. Inputs, Outputs & Success Criteria

## **Inputs**
- Static inventory OR AWS EC2 dynamic inventory plugin  
- Encrypted secrets via **Ansible Vault**  
- SSH private key for Bastion host  
- Optional Git Personal Access Token (PAT)  

## **Outputs**
- Fully configured EC2/VM servers:
  - MySQL database  
  - Django app running via Gunicorn  
  - Nginx acting as a reverse proxy  

## **Success Criteria**
- All playbooks run without errors  
- Database exists and is reachable from the app host  
- Gunicorn is active and serving the Django app  
- Nginx is live and serving HTTP traffic (`/healthz` returns OK)

---

# 🏗️ 3. High-Level Architecture / Flow



             ┌─────────────────────┐
             │      Bastion        │
             │   (SSH Jump Host)   │
             └─────────┬───────────┘
                       │
  ┌────────────────────┼─────────────────────┐
  │                    │                     │
┌───────────┐ ┌─────────────┐ ┌──────────────┐
│ chatdb │ │ chatapp │ │ chatweb │
│ MySQL │◀────▶ │ Django+Gunicorn │ ◀▶ │ Nginx Reverse │
└───────────┘ └─────────────┘ └──────────────┘







### **Architecture Summary**
1. **Inventory** → Defines host groups (`chatdb`, `chatapp`, `chatweb`).  
2. **Playbooks** → Target groups and load vars via `vars_files`.  
3. **Roles** execute tasks such as:
   - Install MySQL  
   - Clone/prepare Django app  
   - Install/Configure Nginx  
4. **Templates** render `.env`, gunicorn service file, nginx site config.  
5. **Handlers** restart services when configurations change.

---

# 📂 4. Repository Layout

### **Top-Level Files**

| File | Purpose |
|------|---------|
| `ansible.cfg` | Defines Ansible configuration (inventory, SSH behavior) |
| `demoplaybook.yml` | Demo playbook for testing (ping, apt, copy) |
| `all.yml` | Global variables like SSH user and ProxyJump settings |
| `inventories.yml` | Static hosts (chatdb, chatapp, chatweb) |
| `aws_ec2.yml` | AWS EC2 dynamic inventory plugin configuration |
| `chatdb.yml` | Playbook for MySQL setup |
| `chatapp.yml` | Playbook for Django+Gunicorn deployment |
| `chatweb.yml` | Playbook for Nginx reverse proxy setup |

---

# 🧩 5. Roles Structure

---

## 📌 **Role: chatdb**

### **Tasks**
- Install MySQL server  
- Update MySQL bind-address  
- Install Python DB drivers (`python3-pymysql`)  
- Create database using `community.mysql.mysql_db`  
- Create user using `community.mysql.mysql_user`  

### **Handlers**
- Restart MySQL service  

### **Variables**
- `db_name`, `db_user`, `unix_login` in `db.yml`
- Secret DB password stored encrypted in `vaults.yml`

---

## 📌 **Role: chatapp**

### **Tasks**
- Update apt packages  
- Install build dependencies  
- Clone application repository (supports PAT-based cloning)  
- Install Python 3.8  
- Create virtual environment  
- Install Python packages from `requirements.txt`  
- Create `/chatapp` directory with proper permissions  
- Generate Django environment file `.env` using `dbconf.j2`  
- Run Django migrations  
- Run `collectstatic`  
- Create systemd service from `guniconf.j2`  
- Enable & start Gunicorn  

### **Templates**
- `dbconf.j2`: DB environment variables for Django  
- `guniconf.j2`: Gunicorn systemd unit  

### **Variables**
- Git credentials (username), service config, DB port stored in `app.yml`  
- Git PAT & DB password stored in encrypted `vaults.yml`

---

## 📌 **Role: chatweb**

### **Tasks**
- Install Nginx  
- Configure reverse proxy using `nginxconf.j2`  
- Remove default Nginx site  
- Create symlink inside `sites-enabled`  
- Run `nginx -t` and reload Nginx  

### **Templates**
- `nginxconf.j2` → Backend proxy + `/healthz`

### **Variables**
- Upstream app server address  
- Nginx config path (`nginx_conf`)

---

# 🔐 6. How Variables & Secrets Flow

| Type | Location | Description |
|------|----------|-------------|
| General Variables | `vars/*.yml` | Used inside playbooks via `vars_files` |
| Secrets | `vars/vaults.yml` | Encrypted with Ansible Vault |
| Connection Vars | inventory files | Controls SSH, bastion access |
| Templates | templates/*.j2 | Render configs based on variables |

---

# 🔐 7. Inventory & SSH (Bastion Setup)

All internal hosts are accessed through a **Bastion (Jump Host)**:  
**IP:** `13.234.116.36`

### SSH Variables:
- `ansible_ssh_private_key_file`: Private key path  
- `ansible_ssh_common_args`: ProxyJump/ProxyCommand string  

⚠️ **Never commit private keys to Git.**

---

