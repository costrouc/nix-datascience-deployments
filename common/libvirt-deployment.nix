{
  deployment.targetEnv = "libvirtd";
  deployment.libvirtd = {
    imageDir = "/var/lib/libvirt/images";
    memorySize = 8096;
    baseImageSize = 15;
    vcpu = 2;
  };
}
