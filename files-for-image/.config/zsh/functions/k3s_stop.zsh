# Stop k3s rootless service
function k3s_stop() {
  echo "Stopping k3s service..."
  systemctl --user stop k3s

  if [ $? -eq 0 ]; then
    echo "k3s service stopped successfully"
    rm "$HOME/.kube/k3s.yaml"
  else
    echo "Failed to stop k3s service"
    return 1
  fi
}
