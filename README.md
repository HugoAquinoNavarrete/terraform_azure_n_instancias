# Creación de "n" instancias tipo ubuntu en Azure usando Terraform

Script en Terraform que automatiza el despliegue en Azure n instancias tipo ubuntu con acceso a internet que permiten tráfico SSH, HTTP y HTTPS

## 1. Ejecuta `az login` para habilitar la conexión con Azure y sigue las indicaciones
Sigue las instrucciones del sitio `https://microsoft.com/devicelogin` e ingresar el código

## 2. Genera un par de llaves rsa pública/privada
   ```bash 
   ssh-keygen
   ```
   Sálvala en el directorio donde correras este script `<ruta_absoluta>/key`, deja vacío `passphrase`

   Cambia los permisos el archivo `chmod 400 key`

## 3. Conexión por SSH a la máquina virtual 
   ```bash
   ssh -v -l azureuser -i key <ip_publica_instancia_creada>
   ```
## 4. Script compatible con la versión de Terraform v0.11.3, estos son los pasos para descargarlo e instalarlo
   ```bash
  wget https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip
  unzip terraform_0.13.3_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  terraform --version 
   ```

## 5. Para ejecutar el script `terraform apply -var "nombre_instancia=<nombre_recursos>" -var "cantidad_instancias=<n>"` cuando el siguiente mensaje aparezca, escribe `yes`:
   ```bash
   Do you want to perform these actions?
     Terraform will perform the actions described above.
     Only 'yes' will be accepted to approve.

     Enter a value:
   ```

Una vez el script se ejecuta generará un mensaje parecido a esto:

   ```bash
   Apply complete! Resources: <cantidad_recursos> added, 0 changed, 0 destroyed.
   ```

## 6. Para eliminar la infraestructura desplegada, ejecuta `terraform destroy` y cuando aparezca el siguiente mensaje, escribe `yes`:
   ```bash
   Do you really want to destroy?
     Terraform will destroy all your managed infrastructure, as shown above.
     There is no undo. Only 'yes' will be accepted to confirm.

     Enter a value:
   ```

El script una vez ejecutado generará un mensaje parecido a esto:

   ```bash
   Destroy complete! Resources: <cantidad_recursos> destroyed.
   ```

En algunas ocasiones en función de la cantidad de recursos creados, hay que ejecutar `terraform destroy` en más de 1 ocasión y de igual manera el tiempo de eliminación es prolongado algunas veces, por lo que no interrumpas la ejecución del mismo.

## 7. Valida en el portal de Azure que los recursos se hayan eliminado

