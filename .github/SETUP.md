# Configuración de GitHub Actions

Este archivo explica cómo configurar los secrets y variables necesarios para que los workflows funcionen correctamente.

## 🔐 Secrets Requeridos (Opcionales)

Los workflows están configurados para funcionar sin AWS, pero si quieres habilitar el despliegue automático, necesitas configurar:

### Para CI/CD Completo:

1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click en **New repository secret**
4. Añade los siguientes secrets:

```
AWS_ACCESS_KEY_ID
  Valor: Tu AWS Access Key ID (obtener de terraform output)

AWS_SECRET_ACCESS_KEY
  Valor: Tu AWS Secret Access Key (obtener de terraform output)
```

### Para Habilitar Despliegue Automático:

1. Ve a **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
2. Añade esta variable:

```
ENABLE_DEPLOYMENT
  Valor: true
```

## 📝 Nota Importante

**Los workflows funcionarán sin estos secrets**, pero con funcionalidad limitada:

### ✅ Sin Secrets (Funciona):
- ✅ Tests de código
- ✅ Linting con flake8 y black
- ✅ Validación de sintaxis de Terraform
- ✅ Escaneo de seguridad básico

### ⚠️ Con Secrets (Funcionalidad Completa):
- ✅ Todo lo anterior +
- ✅ Build y push de imágenes Docker a ECR
- ✅ Despliegue automático a EKS
- ✅ Rollback automático en caso de fallo

## 🔧 Obtener las Credenciales de AWS

Si ya desplegaste la infraestructura con Terraform:

```bash
cd terraform

# Ver el Access Key ID
terraform output github_actions_access_key_id

# Ver el Secret Access Key (sensible)
terraform output github_actions_secret_access_key
```

## 🚫 Deshabilitar Workflows

Si no quieres ejecutar ciertos workflows, puedes:

1. **Opción 1**: No configurar los secrets (los workflows fallarán graciosamente)
2. **Opción 2**: Deshabilitar workflows específicos:
   - Ve a **Actions** → Selecciona el workflow → **...** → **Disable workflow**
3. **Opción 3**: Eliminar los archivos de workflow que no necesites

## 🔒 Seguridad

- ⚠️ **NUNCA** commitees secrets en el código
- ⚠️ **NUNCA** compartas los secrets públicamente
- ✅ Usa GitHub Secrets para almacenar credenciales
- ✅ Rota las credenciales regularmente
- ✅ Usa permisos mínimos necesarios

## 📊 Estado de los Workflows

Puedes ver el estado de los workflows en:
- **Actions** tab en GitHub
- Badge en el README (si lo añades)

## 🆘 Troubleshooting

### Error: "Credentials could not be loaded"
- **Causa**: No están configurados los secrets de AWS
- **Solución**: Configura `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` o ignora este error si no vas a desplegar

### Error: "Code scanning is not enabled"
- **Causa**: GitHub Advanced Security no está habilitado
- **Solución**: Los workflows están actualizados para no requerir esto. Actualiza con el último commit.

### Error: "Tests failed"
- **Causa**: Faltan tests o hay errores en el código
- **Solución**: Los tests básicos ahora están incluidos. Haz pull del último commit.

## 📚 Más Información

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
