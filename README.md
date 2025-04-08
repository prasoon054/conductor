# Conductor Container Tool

This project introduces a simple container management tool that demonstrates building up container primitives in Linux. It is divided into multiple tasks:

- **Task 1 & 2:** Introduce basic container functionalities and the necessary Linux container primitives.
- **Task 3:** Implements a shell script tool, `conductor.sh`, which orchestrates various container operations such as building images, listing images, running containers, and networking.
- **Task 4:** Demonstrates a simple orchestration of two services (external-service and counter-service) using the conductor tool.

---

## Overview

The tool mimics some Docker-like functionalities by:
- **Building images** based on a custom “Conductorfile” (a simplified Dockerfile supporting only a limited `FROM`, `RUN` and `COPY` instructions).
- **Managing images and containers** by listing, removing, running, stopping containers, and more.
- **Providing basic networking** among containers to enable both inter-container communication and controlled Internet access.

### Pre-requisites

Ensure that your system has the following tools installed:
- **debootstrap:** Used for creating base filesystem structures from Debian or Ubuntu packages.
- **iptables:** Required for network configuration.

To install the prerequisites on Ubuntu/Debian, run:

```bash
sudo apt install debootstrap iptables
```

---

## Commands and Functionalities

The conductor tool is implemented in a single Bash script (`conductor.sh`) located in the **Task 3** directory. Below is a summary of each available command and how to use them.

### Build

- **Usage:**  
  ```bash
  ./conductor.sh build <image-name> <conductorfile>
  ```  
  - **Operation:** Downloads and creates an image from a specified Conductorfile. The Conductorfile (a simplified version of Dockerfile) supports only the `FROM`, `RUN`, `COPY` instructions (e.g. `FROM debian:bookworm`, `FROM ubuntu:jammy`, or `FROM ubuntu:focal`).
  - **Details:**  
    - If a conductorfile is not provided as an argument, it defaults to a file named `Conductorfile`.
    - The debootstrap process takes significant time; therefore, the base filesystem is first stored in `.cache/base`, and new images are created as a copy in the `.images/<image-name>` directory.
  - **Example:**  
    ```bash
    ./conductor.sh build myimage Conductorfile
    ```

### Images

- **Usage:**  
  ```bash
  ./conductor.sh images
  ```  
  - **Operation:** Lists all the container images available in the configured images directory.
  - **Example:**  
    ```bash
    ./conductor.sh images
    ```

### Remove Image (rmi)

- **Usage:**  
  ```bash
  ./conductor.sh rmi <image-name>
  ```  
  - **Operation:** Deletes the specified image from the images directory.
  - **Example:**  
    ```bash
    ./conductor.sh rmi myimage
    ```

### Remove Cache (rmcache)

- **Usage:**  
  ```bash
  ./conductor.sh rmcache
  ```  
  - **Operation:** Deletes all cached files including base images. **Use with caution.**
  - **Example:**  
    ```bash
    ./conductor.sh rmcache
    ```

### Run Container

- **Usage:**  
  ```bash
  ./conductor.sh <image-name> <container-name> -- [command <args>]
  ```  
  - **Operation:** Starts a new container named `<container-name>` from the specified `<image-name>`. If no command is provided, it defaults to running `/bin/bash`.
  - **Container Features:**  
    - Isolation: The container uses separate UTS, PID, NET, MOUNT, and IPC namespaces.
    - Filesystems: Mounts `procfs`, `sysfs`, and binds `/dev` to ensure proper functioning of tools like `ps` and `top`.
    - Note: A running container cannot be restarted once exited. It must first be stopped using the **stop** command.
  - **Example:**  
    ```bash
    ./conductor.sh myimage mycontainer -- /bin/bash
    ```

### List Running Containers (ps)

- **Usage:**  
  ```bash
  ./conductor.sh ps
  ```  
  - **Operation:** Displays all running containers by querying entries in the configured container directory.
  - **Example:**  
    ```bash
    ./conductor.sh ps
    ```

### Stop Container

- **Usage:**  
  ```bash
  ./conductor.sh stop <container-name>
  ```  
  - **Operation:** Stops a running container by killing the process that started the container, terminates all container processes, unmounts remaining mount points, and removes the container directory.  
    **Note:** This action will delete all the container state.
  - **Example:**  
    ```bash
    ./conductor.sh stop mycontainer
    ```

### Exec into Container

- **Usage:**  
  ```bash
  ./conductor.sh exec <container-name> -- [command <args>]
  ```  
  - **Operation:** Executes a given command (defaulting to `/bin/bash` if none is provided) within a running container. The executed process shares the container’s namespaces and filesystem configurations.
  - **Example:**  
    ```bash
    ./conductor.sh exec mycontainer /bin/bash
    ```

### Add Network

- **Usage:**  
  ```bash
  ./conductor.sh addnetwork <container-name> [options]
  ```  
  - **Operation:** Adds a network interface to the container and configures its networking parameters.  
    - Without options: Sets up a basic container network where communication is allowed only between two defined interfaces.
    - With the `-i` or `--internet` option: Allows container applications to access the Internet using NAT.
    - With the `--expose` or `-e` option: Maps a container port to a host port to enable external access (e.g., `./conductor.sh addnetwork -e 8080-80` maps host port 80 to container port 8080).
  - **Example:**  
    ```bash
    ./conductor.sh addnetwork mycontainer --internet --expose 8080-80
    ```

### Peer

- **Usage:**  
  ```bash
  ./conductor.sh peer <container1-name> <container2-name>
  ```  
  - **Operation:** Enables networking between two containers which by default are isolated from each other.
  - **Example:**  
    ```bash
    ./conductor.sh peer containerA containerB
    ```

---

## Task 4: Service Orchestration Details

Task 4 is dedicated to orchestrating two services running inside separate containers:

- **External Service:**  
  This service is deployed inside its own container and is configured to be accessible from outside the host (i.e., by other hosts on the network). It includes proper network settings, which means that a port from the container is forwarded to a designated host port. For instance, container port 8080 might be mapped to host port 3000 to allow external access.

- **Counter Service:**  
  This service runs in its own container but is restricted to being accessed only from the host. No port is exposed or forwarded for external communication—this secures the service so that it can only be reached via inter-container communication or via commands executed from the host.

### Code and Configuration Highlights

1. **Container Images and Conductorfiles:**

   - Two separate Conductorfiles have been written—one for each service image:
     - The **external service** image starts from a base (e.g., `FROM debian:bookworm`) and copies the `external-service` code into the image. The image includes necessary package installations such as Python3, Flask, and Requests.
     - The **counter service** image is built similarly but copies the `counter-service` directory and includes steps to update packages, install development tools, and compile the service (using `make`).

2. **Container Launching:**

   - **Running the Containers:**  
     The orchestration starts by running two containers using the build images:
     - For the **external service container** (e.g., named `es-cont`), the command includes network configuration that connects it to the Internet and sets up port forwarding from the container to the host.
     - For the **counter service container** (e.g., named `cs-cont`), the container is started with basic setup and internet connectivity required for internal operations, but no port is exposed externally.

3. **Networking Configuration:**

   - **External Access:**  
     The external service container is configured with network settings that allow it to receive traffic from outside the host. This involves:
     - Setting up NAT rules to map container ports to host ports (for example, mapping container port 8080 to host port 3000).
     - Enabling Internet connectivity directly for the container.
  
   - **Internal Access for Counter Service:**  
     The counter service container is intentionally not configured to expose any ports to the external network. It remains accessible only via the host network. In practical terms, this means:
     - Even though the container has Internet access for updates or internal communications, no external port mapping is created—ensuring that external hosts cannot directly reach the counter service.

4. **Peer Connectivity Between Containers:**

   - Although the services reside in separate containers, the tool supports setting up a peer network between them. This allows the external service (running in `es-cont`) to communicate directly with the counter service (running in `cs-cont`) once the IP address of the counter service container is determined.

5. **Orchestration Script (`service-orchetrator.sh`):**

   - The orchestration of these services is handled by a dedicated script named `service-orchetrator.sh`. Running this script (typically with root permissions) automates the following tasks:
     - Building the images using the corresponding Conductorfiles.
     - Launching the containers with the appropriate network settings.
     - Setting up port-forwarding for the external service.
     - Establishing a peer network between the two containers.
     - Launching the services inside each container by executing the respective start-up commands using the conductor tool.
  
   - **Usage Example:**  
     To run the orchestrator, you would execute:  
     ```bash
     sudo ./service-orchetrator.sh
     ```
     This command ensures that all steps—from image building to service initialization—are carried out in the proper sequence.

---