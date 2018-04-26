---
title: AWS
date: 2018-04-26 05:30:25
tags:
---

# 开始使用 Elastic Container Registry

## 构建、标记和推送 Docker 映像

现在您的存储库已存在，您可以执行以下步骤推送 Docker 映像:

> 已成功创建存储库   
> 123123123.dkr.ecr.us-east-2.amazonaws.com/asdasd-api

安装 AWS CLI 和 Docker 以及有关以下步骤的更多信息，请访问 ECR [文档页面](http://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_GetStarted.html)
1) . 检索您可用来对 Docker 客户端进行身份验证以允许其访问注册表的 `docker login` 命令:

> aws ecr get-login --no-include-email --region us-east-2

2) 运行上一步中返回的 `docker login` 命令。

注意：
如果您使用的是 Windows PowerShell，请改为运行以下命令。

> Invoke-Expression -Command (aws ecr get-login --no-include-email --region us-east-2)

3) 使用以下命令生成 Docker 映像。有关从头开始生成 Docker 文件的信息，请参阅[此处](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html)的说明。如果您已生成映像，则可跳过此步骤:

> docker build -t 123123-api .

4) 生成完成后，标记您的映像，以便将映像推送到此存储库:

> docker tag lucas-api:latest 123123123.dkr.ecr.us-east-2.amazonaws.com/123123-api:latest

5) 运行以下命令将此映像推送到您新创建的 AWS 存储库:

> docker push 213123123123123.dkr.ecr.us-east-2.amazonaws.com/123123-api:latest