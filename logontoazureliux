To log in to Azure using the Ubuntu terminal, follow these steps:

## Instructions

1. **Install Azure CLI:**
   First, you need to install the Azure Command-Line Interface (CLI). Open your terminal and run the following commands to install Azure CLI:

   ```bash
   # Update the repository information
   sudo apt-get update

   # Install the Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Verify the Installation:**
   After the installation is complete, verify that Azure CLI is installed correctly by checking its version:

   ```bash
   az --version
   ```

   This command should display the version of the Azure CLI installed on your system.

3. **Log in to Azure:**
   Use the following command to log in to your Azure account:

   ```bash
   az login
   ```

   This command will open a web browser and prompt you to enter your Azure credentials. If the browser does not open automatically, copy and paste the URL provided in the terminal into your web browser.

4. **Use Service Principal with Client Secret (Optional):**
   If you prefer to log in using a service principal with a client secret, you can use the following command:

   ```bash
   az login --service-principal --username <APP_ID> --password <PASSWORD> --tenant <TENANT_ID>
   ```

   Replace `<APP_ID>`, `<PASSWORD>`, and `<TENANT_ID>` with your service principal's application ID, password, and tenant ID, respectively.

5. **Verify the Login:**
   Once logged in, you can verify your account information by running:

   ```bash
   az account show
   ```

   This command will display details about your currently logged-in account.

## Additional Tips

- **Logout:** To log out of your Azure account, use the following command:

  ```bash
  az logout
  ```

- **Help:** If you need help with any Azure CLI command, you can use the `--help` flag. For example:

  ```bash
  az login --help
  ```

By following these steps, you can successfully log in to Azure using the Ubuntu terminal and start managing your Azure resources.
