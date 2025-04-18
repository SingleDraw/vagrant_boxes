# 🧪 Vagrant + Docker + NGINX Dev Environment

This repository demonstrates a **conceptual setup** for running Docker inside a Vagrant-managed Ubuntu VM, using NGINX in a container to serve static content — all accessible from your **host machine** at `http://localhost:8080`.

The goal is to showcase how to:
- Provision Docker and Docker Compose inside a VM
- Run Docker Compose from the host
- Serve files from a shared directory
- Forward ports cleanly through Docker, VM, and Vagrant

---

## 📁 Directory Layout

```
.
├── workdir
│   ├── html
│   │   └── index.html         # Static HTML page served by NGINX
│   ├── nginx-conf
│   │   └── nginx.conf         # NGINX configuration
│   └── docker-compose.yml     # Defines the NGINX container
├── .gitignore
├── provision.sh               # Installs Docker + Compose in the VM
├── vagrant.sh                 # Wrapper to run Vagrant from Git Bash
└── Vagrantfile                # Vagrant config using ubuntu/jammy64
```

---

## 🚀 Getting Started (Concept Demo)

### Prerequisites

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)
- Git Bash (on Windows, for running the setup script)

### 1. Provision the VM (from Git Bash)

```bash
./vagrant.sh
```

This will:
- Launch a Vagrant VM with **Ubuntu 22.04 (Jammy)**
- Install Docker & Docker Compose
- Expose the Docker daemon via **insecure TCP**
- Set up folder sharing and port forwarding

---

### 2. Run Docker Compose (from Host)

```bash
vagrant ssh vmdocker -c "cd /home/vagrant/app && docker-compose up -d"
```

This will:
- Pull NGINX image into the VM
- Start the container using the Compose file inside the shared `workdir`

---

## 🌍 Accessing the Page

Your static HTML content will be available at:

```
http://localhost:8080
```

---

## 🔁 Flow Overview

1. **NGINX container** serves on `container:80`
2. Docker maps this to `VM:8080`
3. VM’s own NGINX (optional) can forward `8080 → 80` internally
4. **Vagrant** maps `VM:80 → Host:8080`

🧩 All files come from the shared `workdir/` directory, editable from the host.

---

## 🛠 Use Cases

This setup is a **starter template** for:
- Trying out Docker inside a Vagrant-managed VM
- Learning how Vagrant, Docker, and Compose can integrate
- Experimenting with NGINX config in a safe sandbox
- Building a simple testbed for web content delivery

---

## ⚠️ Warning

This is an **insecure development example**:
- The Docker daemon is exposed via TCP without authentication
- **Never** use this in production environments

---

## 🧹 Cleanup

To tear down the VM:

```bash
vagrant destroy
```

---

## 📦 Base Box

- Box: [`ubuntu/jammy64`](https://app.vagrantup.com/ubuntu/boxes/jammy64)
- OS: Ubuntu 22.04 LTS

---

## 📄 License

MIT License
