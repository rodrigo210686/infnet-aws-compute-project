Perfeito ✅
Com base no conteúdo do arquivo `terraform.json`, segue um **README.md** objetivo e completo explicando a arquitetura e como configurá-la em outro ambiente.

---

# 🚀 Projeto INFNET AWS Compute — Infraestrutura Terraform

## 📘 Visão Geral

Este projeto provisiona uma **arquitetura AWS altamente disponível** composta por:

* **VPC** (`10.0.0.0/16`) com sub-redes públicas e privadas distribuídas em duas zonas de disponibilidade (`us-east-1a`, `us-east-1b`);
* **NAT Gateway** e **Internet Gateway** para saída de tráfego controlada;
* **Application Load Balancer (ALB)** público com regras HTTP (porta 80) integradas ao Auto Scaling Group;
* **Auto Scaling Group (ASG)** com **Launch Template** baseado na AMI `ami-0360c520857e3138f` (Ubuntu/Apache test instance);
* **Security Groups** separados para o ALB e para as instâncias EC2;
* **S3 Website** público versionado, com criptografia AES-256 e endpoint configurado para hospedagem estática;
* **Outputs** com IDs principais (VPC, Subnets, Security Groups, Target Group, Launch Template, etc.) para integração com outros módulos.

---

## 🧱 Estrutura de Módulos

| Módulo              | Recursos Principais                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **networking**      | VPC, Subnets Públicas e Privadas, Route Tables, NAT Gateway, IGW                                                      |
| **security_group**  | SG para ALB (HTTP/HTTPS) e SG para EC2                                                                                |
| **alb**             | Application Load Balancer + Listener HTTP                                                                             |
| **lb_target_group** | Target Group para ASG                                                                                                 |
| **launch_template** | Template EC2 (t2.micro) com user-data de inicialização (Apache + metadados dinâmicos + HTML de diagnóstico)           |
| **auto-scaling**    | Auto Scaling Group com 2 instâncias mínimas ligadas ao Target Group                                                   |
| **s3**              | Bucket público “`infnet-aws-compute-project-website-bucket`” com versionamento, ACL pública e configuração de website |

---

## 🌐 Arquitetura Simplificada

```
                  +-------------------------+
                  |   S3 Static Website     |
                  | infnet-aws-compute...   |
                  +-----------+-------------+
                              |
                              v
        Internet ---> [ Application Load Balancer ]
                              |
                              v
         +---------------------------------------------+
         | Auto Scaling Group (t2.micro EC2 Instances) |
         | AZs: us-east-1a / us-east-1b               |
         +---------------------------------------------+
                  |                 |
          Private Subnet A     Private Subnet B
                  |                 |
                  +------ NAT Gateway ------+
                              |
                          Public Subnet
                              |
                          Internet Gateway
```

---

## ⚙️ Pré-requisitos

* **Terraform** v1.7.4 ou superior
* **AWS CLI** configurado (`aws configure`)
* Credenciais IAM com permissão de **AdministratorAccess** ou políticas equivalentes
* Bucket remoto para o estado (caso utilize `backend "s3"`)

---

## 🪜 Passos para Execução

1. **Clone o repositório**

   ```bash
   git clone https://github.com/seu-repo/infnet-aws-compute.git
   cd infnet-aws-compute
   ```

2. **Configure variáveis**

   Edite o arquivo `terraform.tfvars` com os valores do seu ambiente:

   ```hcl
   bucket_name       = "meu-remote-state-bucket"
   environment       = "infnet-1"
   vpc_cidr          = "10.0.0.0/16"
   region            = "us-east-1"
   ```

3. **Inicialize o Terraform**

   ```bash
   terraform init
   ```

4. **Valide e visualize o plano**

   ```bash
   terraform plan
   ```

5. **Aplique a infraestrutura**

   ```bash
   terraform apply -auto-approve
   ```

6. **Saídas úteis**

   Após o apply, visualize os recursos criados:

   ```bash
   terraform output
   ```

   Exemplo:

   ```
   infnet_proj_1_vpc_id = "vpc-0e354e0f0635b7152"
   infnet_proj_1_lb_target_group_arn = "arn:aws:elasticloadbalancing:..."
   infnet_proj_1_private_subnets = ["subnet-0835...", "subnet-0233..."]
   ```

---

## 🧩 Customizações Possíveis

* Alterar **AMI** ou **instância EC2** no módulo `launch_template`
* Ativar **HTTPS** adicionando certificados ACM ao ALB
* Alterar **políticas do bucket S3** para acesso restrito
* Integrar o ALB ao **CloudFront** para caching global
* Ajustar **ASG Min/Max Capacity** conforme demanda

---

---

## Code Commit App Code to upload

```sh
cd /root/terraform/infnet-aws-compute-project/infnet-aws-compute-project/template/app
git init
git add .
git commit -m "initial commit for infnet app"

# Configure helper para CodeCommit (HTTPS)
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Adicione remote (substitua REGION e REPO_NAME se necessário)
git remote add origin https://git-codecommit.<REGION>.amazonaws.com/v1/repos/infnet-app-repo

# Force criar branch main e push
git branch -M main
git push -u origin main

##  EXECUTAR O JOB MANUALMENTE
# obter o nome do projeto
PROJECT=$(terraform output -raw codebuild_project_name)
aws codebuild start-build --project-name "$PROJECT"

```



## 🔍 Troubleshooting

| Sintoma                         | Causa provável                              | Solução                                                |
| ------------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| ALB sem instâncias registradas  | ASG não associou instâncias ao Target Group | Verifique `target_group_arns` no módulo ASG            |
| Bucket S3 sem acesso público    | `block_public_acls` pode estar habilitado   | Ajuste `aws_s3_bucket_public_access_block`             |
| Página HTML sem dados dinâmicos | Erro no `user_data`                         | Confirme que o script foi base64-encodado corretamente |

---

## 📎 Endpoints de exemplo

* **ALB DNS:** `infnet-proj-1-alb-1839838188.us-east-1.elb.amazonaws.com`
* **S3 Website:** `http://infnet-aws-compute-project-website-bucket.s3-website-us-east-1.amazonaws.com`

---



## ECS / CodeCommit / CodeBuild — Guia Rápido

Este projeto provisiona infraestrutura para executar uma aplicação containerizada em ECS (EC2 launch type), com repositório ECR e pipeline de build via CodeBuild. Abaixo os passos para integrar e testar a aplicação localizada em `./template/app`.

### Pré-requisitos
- AWS CLI configurado (credenciais & região)
- Terraform instalado
- Git instalado
- Permissões IAM suficientes para criar recursos (ECR, CodeCommit, CodeBuild, ECS, EC2, ASG, VPC, IAM, S3)

### Módulos relevantes
- `module.ecr` — cria o repositório ECR
- `module.codecommit` — cria o repositório CodeCommit
- `module.codebuild` — cria o projeto CodeBuild (usa CodeCommit como source)
- `module.ecs` — cluster ECS, LT, ASG, capacity provider, task definition
- `module.networking` — VPC, subnets privadas, endpoints (ECR, ECS, SSM, etc.)

### 1) Criar recursos com Terraform
No root do repo:
```bash
terraform init
terraform plan
terraform apply
```
Após o `apply` você terá outputs expostos (por exemplo `module.ecr.repository_url`, `module.codecommit.clone_url_http`, `codebuild_project_name`).

### 2) Enviar código local para CodeCommit
No diretório do app:
```bash
cd template/app
git init
git add .
git commit -m "initial commit for infnet app"

# Habilita helper de credenciais do CodeCommit (HTTPS)
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Adiciona remote (substitua <REGION> ou use o output do Terraform)
git remote add origin $(terraform output -raw codecommit_clone_url)

# Force branch main e push
git branch -M main
git push -u origin main
```

Se preferir SSH, use `clone_url_ssh` do output do módulo CodeCommit.

### 3) Disparar build no CodeBuild
Obtenha o nome do projeto e inicie o build:
```bash
PROJECT=$(terraform output -raw codebuild_project_name)
aws codebuild start-build --project-name "$PROJECT"
```
O build irá:
- Fazer login no ECR
- Buildar a imagem (procura `Dockerfile` em `template/app` ou `app`)
- Taggar e pushar para ECR

Se o build falhar por caminho (ex.: `cd template/app`), ajuste o repositório CodeCommit para conter esses arquivos no mesmo layout ou atualize o `buildspec.yml` no módulo codebuild para apontar ao caminho correto.

### 4) Garantir que ECS use a imagem
No root module passamos a URL do ECR para o módulo ECS:
```hcl
module "ecs" {
  source = "./ECS"
  ecr_repository_url = module.ecr.repository_url
  # ... outros inputs ...
}
```
Dependência de criação:
- Para garantir que o repositório exista antes do ECS, o módulo root usa `depends_on = [module.ecr]`.
- Se quiser que Terraform dispare o build e espere a imagem pronta, há a opção de criar um `null_resource` que chama `aws codebuild start-build` e faz polling até o build terminar — isso requer AWS CLI no host que executa o Terraform.

### 5) Testar a imagem localmente (opcional)
Faça pull e rode localmente:
```bash
# login
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

REPO_URL=$(terraform output -raw ecr_repository_url)
docker pull ${REPO_URL}:latest
docker run -d -p 8080:80 ${REPO_URL}:latest
curl http://localhost:8080
```

### 6) Verificações no ECS após deploy
- No Console ECS: verifique cluster, capacity providers e instâncias registradas.
- No Console EC2: verifique instâncias do ASG, role/instance profile anexados.
- No Console ECR: confirme tags da imagem (latest e commit hash).
- No CloudWatch Logs: veja logs do CodeBuild e da aplicação (se configurado).

### Troubleshooting rápido
- Erro `No outputs found` ao rodar `terraform output -raw codebuild_project_name`:
  - Adicione no root `outputs.tf`:
    ```hcl
    output "codebuild_project_name" {
      value = module.codebuild.codebuild_project_name
    }
    ```
  - Rode `terraform apply`/`terraform refresh`.
- Build falha com `cd: can't cd to template/app`:
  - Certifique-se que o repo CodeCommit contém o diretório `template/app`, ou ajuste `buildspec.yml` para caminho real.
- `Invalid IAM Instance Profile name` ao criar ASG/Launch Template:
  - Crie `aws_iam_instance_profile` e passe o nome correto para `iam_instance_profile` na LT.
- Route table "flapping":
  - Remova o bloco `route` embutido e use `aws_route` separado para o default route via NAT.



## 🧾 Licença

Projeto acadêmico de demonstração — uso livre para fins de estudo e prática de infraestrutura como código (IaC).

---
