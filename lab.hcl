resource "network" "lab_net" {
  subnet = "10.200.0.0/24"
}

resource "vm" "desktop" {
  image {
    name = "europe-west1-docker.pkg.dev/instruqt/instruqt-sandbox/ubuntu-2204:latest"
  }
  environment = {
    "VNC_PASSWORD" = "instruqt"
  }
  startup_script = <<-EOT
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y xfce4 xfce4-terminal tigervnc-standalone-server dbus-x11

    mkdir -p /root/.vnc
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
    chmod 600 /root/.vnc/passwd

    cat > /root/.vnc/xstartup << 'XSTARTUP'
    #!/bin/sh
    unset SESSION_MANAGER
    unset DBUS_SESSION_BUS_ADDRESS
    exec startxfce4
    XSTARTUP
    chmod +x /root/.vnc/xstartup

    # Use Xtigervnc directly to avoid the vncserver wrapper's interactive password prompt.
    # Redirect output to /dev/null so background processes don't hold stdout/stderr
    # pipes open, which would cause the executor to hang waiting for EOF.
    Xtigervnc :1 -geometry 1280x800 -depth 24 -localhost 0 -SecurityTypes VncAuth -rfbauth /root/.vnc/passwd </dev/null >/dev/null 2>&1 &
    sleep 2

    # Start the desktop session
    export DISPLAY=:1
    /root/.vnc/xstartup </dev/null >/dev/null 2>&1 &
  EOT
  config {
  }
  network {
    id         = resource.network.lab_net.meta.id
    ip_address = "10.200.0.10"
  }
  resources {
    cpu    = 4
    memory = 8192
  }
  health_check {
    timeout = "10m"
    tcp {
      address = "10.200.0.10:5901"
    }
  }
}

resource "container" "guacamole" {
  image {
    name = "flcontainers/guacamole:latest"
  }
  environment = {
    "EXTENSIONS" = "auth-header"
  }
  volume {
    source      = "/guacamole"
    destination = "/config"
  }
  network {
    id         = resource.network.lab_net.meta.id
    ip_address = "10.200.0.20"
  }
  port {
    local           = "8080"
    open_in_browser = "/"
  }
  resources {
    cpu    = 1000
    memory = 512
  }
}

resource "template" "guacamole_config" {
  source      = "files/user-mapping.xml"
  destination = "/guacamole/user-mapping.xml"

  variables = {
    vnc_host     = "10.200.0.10"
    vnc_port     = "5901"
    vnc_password = "instruqt"
  }
}

resource "service" "guacamole" {
  target = resource.container.guacamole
  port   = 8080
  path   = "/"
}

resource "terminal" "desktop" {
  target = resource.vm.desktop
}

resource "layout" "main" {
  column {
    tab "desktop_ui" {
      title  = "Desktop"
      target = resource.service.guacamole
    }
    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.desktop
    }
  }

  column {
    instructions {
    }
  }
}

resource "page" "intro" {
  title = "Introduction"
  file  = "instructions/intro.md"

}

resource "lab" "vm_guacamole" {
  title       = "VM Desktop via Guacamole"
  description = "Ubuntu VM with XFCE desktop accessible through Guacamole in the browser."

  settings {
    idle {
      enabled      = false
      show_warning = false
    }
    timelimit {
      duration = "1h"
    }
  }

  layout = resource.layout.main

  content {
    chapter "getting_started" {
      title = "Getting Started"

      page "intro" {
        reference = resource.page.intro
      }
    }
  }
}
