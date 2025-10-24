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

## 🧾 Licença

Projeto acadêmico de demonstração — uso livre para fins de estudo e prática de infraestrutura como código (IaC).

---
