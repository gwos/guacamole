bash "run xvfb and x11vnc server" do
    not_if "ps aux | grep -v grep | grep x11vnc", :user => 'ubuntu'
    user "ubuntu"
    cwd "/home/ubuntu"
    code <<-EOH
        export DISPLAY=:1
        Xvfb :1 -screen 0 1024x768x16&
        daemonize /usr/bin/fluxbox
        daemonize /usr/bin/x11vnc -display :1 -forever
    EOH
end
