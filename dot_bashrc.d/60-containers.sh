# Enter the workbox Distrobox, creating it from the host Fedora version if needed.
workbox() {
    local fedora_version
    fedora_version=$(grep -oP 'VERSION_ID=\K\d+' /etc/os-release)
    local image="fedora-toolbox:${fedora_version}"

    if distrobox list | grep -q "workbox"; then
        distrobox enter workbox
    else
        echo "Creating workbox from ${image}..."
        if distrobox create --pull --name workbox --image "${image}"; then
            echo "Container created successfully. Entering workbox..."
            distrobox enter workbox
        else
            echo "Failed to create container"
            return 1
        fi
    fi
}

alias docker='podman'
alias wb='workbox'
