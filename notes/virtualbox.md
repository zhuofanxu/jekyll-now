# VBox Centos 多vm之间互通以及各vm与host互通并保持vm IP相对固定(host角度)

## 解决方案 
虚拟机使用Nat network 与 Host only 混合模式；其中 Nat network 为vm提供外网访问能力，Host only 提供vm与host以及vm与vm之间的访问能力。

vm 配置两个网卡，其中host-only模式，vm 通过 host 上的虚拟网卡与 host 主机处于同一局域网中，该虚拟网卡名为 `vboxnet0`

因为同一局域网下的设备可以相互访问，这样便实现了vm 与 host、vm 与 vm 的互通。

而Nat 模式下，vm 则通过 host 作为代理，进行外网的访问。


## VBox 设置

1. 在 vbox 偏好设置里设置添加 NAT网络
    
    偏好设置—>网络—>点击右边的加号，添加一个 NAT网络
2. 在 vbox 主机网络管理添加 host-only 网卡
    
    文件->主机网络管理->创建 host-only

    如果已经存在vboxnet0则忽略此步骤
3. 在安装好的vm 设置中添加两个网卡 分别是 NAT网络、仅主机（HOST-Only）网络。

4. 进入vm 进行网卡配置

    ```shell
      su -
      cd /etc/sysconfig/network-scripts/
      vi ifcfg-enp0s3(Nat 网卡对应的配置文件)
    ```
    如果ONBOOT 不是yes 则修改为yes

    ```shell
      cp ifcfg-enp0s3 ifcfg-enp0s8(host-only网卡对应的配置文件)
      vi ifcfg-enp0s8
    ```
    BOOTPROTO=dhcp 改为 BOOTPROTO=static
    NAME=enp0s3 改为 NAME=enp0s8 DEVICE=enp0s3 改为 DEVICE=enp0s8

    UUID 修改，UUID可以重新生成一个，可使用uuidgen生成

    添加 IPADDR=192.168.99.11(根据主机`vboxnet0`网卡的网关信息指定有效的ip, 我这边是192.168.99.1) NETMASK=255.255.255.0


    最后保存文件

5. 重启网络
   ```shell
    service network restart
   ```