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

resource "terminal" "desktop" {
  target = resource.vm.desktop
}

resource "layout" "main" {
  column {
    tab "desktop_ui" {
      title  = "Desktop"
      target = resource.container.guacamole
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

resource "task" "setup_desktop" {
  description = "Install desktop environment"

  config {
    target  = resource.vm.desktop
    timeout = "600s"
  }

  condition "install" {
    description = "Install XFCE and VNC"

    setup {
      script = "scripts/setup_desktop.sh"
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
