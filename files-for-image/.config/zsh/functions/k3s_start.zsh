# Start k3s rootless service
function k3s_start() {
    echo "Starting k3s service..."
    systemctl --user start k3s

    if [ $? -eq 0 ]; then
        echo "k3s service started successfully"
        echo "Waiting for k3s to be ready..."

        # Wait for kubeconfig to be created
        local max_wait=30
        local waited=0
        while [ ! -f "$HOME/.local/share/k3s/server/cred/admin.kubeconfig" ] && [ $waited -lt $max_wait ]; do
            sleep 1
            waited=$((waited + 1))
        done

        if [ -f "$HOME/.local/share/k3s/server/cred/admin.kubeconfig" ]; then
            echo "k3s is ready!"
            echo ""
            echo "To use kubectl with k3s, set:"
            echo "  export KUBECONFIG=\$HOME/.local/share/k3s/server/cred/admin.kubeconfig"
        else
            echo "Warning: kubeconfig not found after ${max_wait}s. Check service status with: systemctl --user status k3s"
        fi
    else
        echo "Failed to start k3s service"
        return 1
    fi
}
