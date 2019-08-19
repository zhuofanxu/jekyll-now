## Dockerfile multi-state builds

    Where possible, use multi-stage builds, and only copy the artifacts you need into the final image. This allows you to include tools and debug information in your intermediate build stages without increasing the size of the final image.
    ---
    尽可能的使用多阶段构建镜像，仅复制最核心的部件到最终的镜像。这样一些工具库、debug 信息等仅会存在中间阶段的镜像，不会影响最终镜像的大小。

## Docker search tag

    使用 registry API 通过 shell python 脚本执行获取 脚本可以软连接到可执行目录 如 /urs/local/bin
    docker-tags $rep-name