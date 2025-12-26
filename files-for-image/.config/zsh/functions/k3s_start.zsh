# Start k3s rootless service
function k3s_start() {

  if systemctl --user is-active --quiet k3s; then
    echo "k3s is already running."
    return 0
  fi

  echo "Starting k3s service..."

  rm -f "$HOME/.kube/k3s.yaml"

  systemctl --user start k3s

  if [ $? -eq 0 ]; then
    echo "k3s service started successfully"
    echo "Waiting for k3s to be ready..."

    # Wait for kubeconfig to be created
    local max_wait=30
    local waited=0
    while [ ! -f "$HOME/.kube/k3s.yaml" ] && [ $waited -lt $max_wait ]; do
      sleep 1
      waited=$((waited + 1))
    done

    if [ -f "$HOME/.kube/k3s.yaml" ]; then
      echo "k3s is ready!"
      echo ""
      echo "To use kubectl with k3s in another shell, set:"
      echo "  export KUBECONFIG=\$HOME/.kube/k3s.yaml"
      export KUBECONFIG="$HOME/.kube/k3s.yaml"
      sed 's/default/k3s_local/' $KUBECONFIG -i
    else
      echo "Warning: kubeconfig not found after ${max_wait}s. Check service status with: systemctl --user status k3s"
    fi
  else
    echo "Failed to start k3s service"
    return 1
  fi
}
