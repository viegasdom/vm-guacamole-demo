<instruqt-task id="setup">Setting up the desktop environment...</instruqt-task>

## VM Desktop via Guacamole

This lab runs an Ubuntu VM with an XFCE desktop environment, accessible through Apache Guacamole in the browser.

### Tabs

- **Desktop** - graphical desktop via Guacamole (VNC)
- **Terminal** - command line into the VM

### Access the desktop

Click the **Desktop** tab. Log in with:
- Username: `instruqt`
- Password: `instruqt`

You should see the XFCE desktop. You can open a terminal, file manager, or any graphical application from within the desktop.

### From the terminal

You can also access the VM via the **Terminal** tab and run commands directly:

```bash
vncserver -list
```

This shows the running VNC sessions.
