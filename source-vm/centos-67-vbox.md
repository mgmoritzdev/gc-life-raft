# [Importing Boot Disk Images to Compute Engine on Google Cloud](https://cloud.google.com/compute/docs/images/import-existing-image)
Overview

To import a boot disk image to Compute Engine, use the following process:

1. Plan your import path. You must identify where you are going to prepare your boot disk image before you upload it, and how you are going to connect to that image after it boots in the Compute Engine environment.

The process described in here is going to be made using an Cent OS 6.7 Version. We are going to use Oracle Virtual Box. Terminal and command line usage on both virtualization platforms will be prioritezed. 

2. Install new operational system, target is one of the choices present [here](http://vault.centos.org/6.7/isos/x86_64/). Option of choice for this work will be the [minimal version](http://vault.centos.org/6.7/isos/x86_64/CentOS-6.7-x86_64-minimal.iso). Sometimes the iso link may be a little troublesome of being download, specially because it triggers a page instead of the actual iso file. To fix this, install [aria2c](https://aria2.github.io/) and then: 

```
aria2c https://aria2.github.io/
```

*Debt*: learn and simplify VBoxManage command to create new vm with all the requirements demanded for this work to succeed. 

3. After installation, execute the following commands in order to make it better: 

``` 
yum update -y && yum upgrade -y
```

shutdown vm and clone it. Let's assume from now on that the first version
2. Prepare your boot disk so it can boot within the Compute Engine environment and so you can access it after it boots.

3. Create and compress the boot disk image file.

5. Upload the image file to Google Cloud Storage and import the image to Compute Engine as a new custom image.

6. Use the imported image to create a virtual machine instance and make sure it boots properly.

7. Optimize the image and install the Linux Guest Environment so that your imported operating system image can communicate with the metadata server and use additional Compute Engine features.

8. If the image does not successfully boot, you can troubleshoot the issue by attaching the boot disk image to another instance and reconfiguring it.

```
Suggestion is that throughout the process that the source vm is froken as much as it can. That can be accomplished by cloning the source image as many time as needed at any major step taken.
``` 

