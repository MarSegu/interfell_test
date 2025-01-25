# interfell_test
This repository has the resolution of the interfell ingress test

# Propuesta de Infraestructura

## 1. Diagrama de alto nivel de la infraestructura propuesta

La solución necesita abordar la escalabilidad y eficiencia de costos. A continuación, se presentan dos alternativas para la arquitectura:

### Alternativa 1: Uso de AWS Lambda y Step Functions
**Descripción:**
- Sustituimos el cron job y el script por una arquitectura serverless.
- **AWS Lambda** maneja las transacciones en lotes, con una función específica para confirmar cada una.
- **AWS Step Functions** coordina el flujo de trabajo para garantizar que cada transacción se procesa y marca correctamente.
- **DynamoDB** reemplaza la base de datos existente, proporcionando escalabilidad y bajo tiempo de respuesta.

### Alternativa 2: Uso de Amazon ECS (Fargate)
**Descripción:**
- Desplegamos un contenedor en **Amazon ECS** con **Fargate** para ejecutar el proceso de confirmación.
- El contenedor ejecutará un servicio continuamente escalable, evitando la limitación de los cron jobs.
- **Amazon RDS (Aurora Serverless)** se utiliza para la base de datos.

## 2. Archivos en Terraform o CloudFormation

**Estructura del proyecto:**
- **/diagrams**: Archivos para el diagrama de arquitectura.
- **/terraform/alternative1**: Terraform para Lambda y Step Functions.
- **/terraform/alternative2**: Terraform para ECS y Fargate.

Para cada alternativa, incluiré recursos como:
- Red VPC.
- Bases de datos (DynamoDB o Aurora Serverless).
- Lambda, Step Functions o ECS.
- Roles y políticas de IAM.

## 3. Estructura del Pipeline Automatizado

El pipeline automatizado se diseñará con **Azure DevOps**:

### Etapas:
1. **Azure DevOps como repositorio fuente.**
2. **Build** para empaquetar y validar el código.
3. **Terraform Validate** para comprobar la configuración de Terraform.
4. **Terraform Plan** para previsualizar los cambios que se aplicarán.
5. **Manual Validation** para una revisión y validación manual antes de aplicar los cambios.
6. **Terraform Apply** para aplicar los cambios a la infraestructura.

## 4. Herramientas de monitoreo

- **Amazon CloudWatch** para logs, métricas y alarmas.
- **AWS X-Ray** para rastreo de transacciones y detectar cuellos de botella.
- **DynamoDB Metrics** para monitorear uso de la base de datos (alternativa 1).
- **RDS Performance Insights** para analizar consultas en Aurora Serverless (alternativa 2).
