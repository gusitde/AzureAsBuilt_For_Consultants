# Asbuilt For Azure
As Built Azure documentation

# As-Built Document Generation Script

This script generates an As-Built document for Azure resources within specified subscription IDs. It gathers data about various Azure services, processes the information, and creates a Word document summarizing the details.

## Features

- **Logging**: Logs operations to a file and the console to track progress and errors.
- **Azure Integration**: Uses Azure SDKs to fetch information about various resources.
- **Word Document Generation**: Creates a structured Word document with custom styling, table formatting, and detailed resource information.

## Prerequisites

- Python 3.x
- Required Python packages:
  - `azure-identity`
  - `azure-mgmt-resource`
  - `azure-mgmt-network`
  - `python-docx`

You can install these packages using pip:

```bash
pip install azure-identity azure-mgmt-resource azure-mgmt-network python-docx
```

## Environment Variables

Set the `AZURE_SUBSCRIPTION_IDS` environment variable with a comma-separated list of the subscription IDs you want to query.

## Script Overview

### Configure Logging

Sets up logging to capture all levels of logs and write them to a file (`asbuiltlogs.txt`) and to the console.

### Define Resource Mappings

Maps Azure resource types to their service names and descriptions.

### Load Azure Data

Authenticates using `DefaultAzureCredential` and initializes clients for resource and network management.

### Fetch Resources

Retrieves all resources for the given subscription IDs and organizes them by type.

### Fetch Network Details

Retrieves specific details for network resources like Virtual Networks (VNets).

### Process Resource Data

Processes the fetched resource data to extract relevant information and update resource counts.

### Generate Document

Creates a Word document with the fetched data, including:
- Title Page
- Summary Section
- Total Counts Section
- Table of Contents
- Detailed Sections for each Azure service

### To Logon to Azure sing Ubuntu Terminal
https://github.com/gusdellazure/asbuilt/blob/main/logontoazureliux.md

### Main Function

Coordinates the data loading, processing, and document generation.

```python
import os
import logging
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from docx import Document
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.shared import Pt, RGBColor
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

# Configure logging
log_filename = 'asbuiltlogs.txt'
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[
                        logging.FileHandler(log_filename, mode='w'),
                        logging.StreamHandler()
                    ])

# Mapping of resource types to Azure service names and descriptions
RESOURCE_TYPE_DETAILS = {
    "Microsoft.CognitiveServices/accounts": ("Azure Cognitive Services", "Provides AI and machine learning services."),
    # (Additional mappings omitted for brevity)
}

# Define specific headers for each Azure service type
SERVICE_HEADERS = {
    "Azure Virtual Machines": ["Name", "Resource Group", "Location", "Size", "OS Type", "Tags"],
    "Azure Virtual Networks": ["Name", "Resource Group", "Location", "Address Space", "Tags"],
    # (Additional headers omitted for brevity)
}

def load_azure_data(subscription_ids):
    """Load data from Azure for given subscription IDs."""
    logging.info("Loading Azure data for subscription IDs.")
    credential = DefaultAzureCredential()
    resource_clients = [{"client": ResourceManagementClient(credential, sub_id), "subscription_id": sub_id} for sub_id in subscription_ids]
    network_clients = [{"client": NetworkManagementClient(credential, sub_id), "subscription_id": sub_id} for sub_id in subscription_ids]
    return resource_clients, network_clients

def fetch_resources(resource_clients):
    """Fetch all resources for given clients and organize them by type."""
    all_resources = {}
    for client_info in resource_clients:
        client = client_info["client"]
        sub_id = client_info["subscription_id"]
        try:
            logging.info(f"Fetching resources for client with subscription ID {sub_id}.")
            resources = client.resources.list()
            for resource in resources:
                resource_type = resource.type
                if resource_type not in all_resources:
                    all_resources[resource_type] = []
                all_resources[resource_type].append(resource.as_dict())
        except Exception as e:
            logging.error(f"Error fetching data for client with subscription ID {sub_id}: {e}")
    return all_resources

def fetch_network_details(network_clients):
    """Fetch details for specific network resources like VNets."""
    network_details = {}
    for client_info in network_clients:
        client = client_info["client"]
        sub_id = client_info["subscription_id"]
        try:
            logging.info(f"Fetching network details for client with subscription ID {sub_id}.")
            vnets = client.virtual_networks.list_all()
            network_details['virtualNetworks'] = [vnet.as_dict() for vnet in vnets]
        except Exception as e:
            logging.error(f"Error fetching network details for client with subscription ID {sub_id}: {e}")
    return network_details

def process_resource_data(resources, network_details):
    """Process resource data to extract relevant information."""
    sections = []
    counts = {
        "subscriptions": len(resources),
        "resource_groups": set(),
        "virtual_machines": 0,
        "disks": 0,
        "storage_accounts": 0,
        "vnets": 0,
    }

    for resource_type, resource_list in resources.items():
        logging.debug(f"Processing resource type: {resource_type}")
        service_name, service_description = RESOURCE_TYPE_DETAILS.get(resource_type, (resource_type, "Description not available."))
        logging.debug(f"Service name: {service_name}, Description: {service_description}")
        section_content = []
        for resource in resource_list:
            counts["resource_groups"].add(resource.get('resourceGroup', 'N/A'))
            if resource_type == "Microsoft.Compute/virtualMachines":
                counts["virtual_machines"] += 1
            elif resource_type == "Microsoft.Compute/disks":
                counts["disks"] += 1
            elif resource_type == "Microsoft.Storage/storageAccounts":
                counts["storage_accounts"] += 1
            elif resource_type == "Microsoft.Network/virtualNetworks":
                counts["vnets"] += 1

            resource_details = {
                "Name": resource.get('name', 'N/A'),
                "Resource Group": resource.get('resourceGroup', 'N/A'),
                "Location": resource.get('location', 'N/A'),
                "Kind": resource.get('kind', 'N/A'),
                "SKU": resource.get('sku', {}).get('name', 'N/A'),
                "Tags": resource.get('tags', 'N/A'),
                "ID": resource.get('id', 'N/A')
            }

            if resource_type == "Microsoft.Network/virtualNetworks":
                resource_details["Address Space"] = ', '.join(resource.get('addressSpace', {}).get('addressPrefixes', []))

            section_content.append(resource_details)
        sections.append({
            "title": f"Service: {service_name}",
            "description": service_description,
            "content": section_content
        })

    counts["resource_groups"] = len(counts["resource_groups"])

    logging.info(f"Processed resource data: {counts}")
    return sections, counts

def remove_empty_columns(headers, content):
    """Remove columns that are entirely empty from headers and content."""
    non_empty_headers = []
    non_empty_content = []
    for idx, header in enumerate(headers):
        if any(item.get(header, 'N/A') != 'N/A' for item in content):
            non_empty_headers.append(header)

    for item in content:
        non_empty_item = {k: v for k, v in item.items() if k in non_empty_headers}
        non_empty_content.append(non_empty_item)

    return non_empty_headers, non_empty_content

def add_custom_styles(doc):
    """Add custom styles to the Word document."""
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Aptos'
    font.size = Pt(12)
    font.color.rgb = RGBColor(0, 0, 0)

def set_table_borders(table):
    """Set borders for all cells in a table and add outside borders."""
    tbl = table._tbl
    tblBorders = OxmlElement('w:tblBorders')
    for border_name in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        border = OxmlElement(f'w:{border_name}')
        border.set(qn('w:val'), 'single')
        border.set(qn('w:sz'), '6')
        border.set(qn('w:space'), '0')
        border.set(qn('w:color'), 'auto')
        tblBorders.append(border)
    tbl.tblPr.append(tblBorders)

def format_table_header(table, headers):
    """Format table header with bold letters, white font color, and a light blue background."""
    hdr_cells = table.rows[0].cells
    for idx, header in enumerate(headers):
        hdr_cells[idx].text = header
        cell_para = hdr_cells[idx].paragraphs[0]
        cell_run = cell_para.runs[0]
        cell_run.bold = True
        cell_run.font.color.rgb = RGBColor(255, 255, 255)
        cell_run.font.size = Pt(12)
        
        cell_tcPr = hdr_cells[idx]._element.get_or_add_tcPr()
        cell_shading = OxmlElement('w:shd')
        cell_shading.set(qn('w:fill'), '87CEEB')
        cell_tcPr.append(cell_shading)

def generate_document(sections, counts, filename='asbuilt.docx'):
    """Generate a Word document with the given sections and counts."""
    doc = Document()
    add_custom_styles(doc)

    title_page = doc.add_paragraph()
    title_page.add_run("As-Built Document").bold = True
    title_page.alignment = WD_PARAGRAPH_ALIGNMENT.CENTER
    doc.add_paragraph("\n\n\n\n\n")

    doc.add_heading('Summary', level=1)
    doc.add_paragraph(
        "This As-Built Document provides a comprehensive overview of the current state of Azure resources "
        "within the specified subscription IDs. It includes detailed information about various services, "
        "such as Virtual Machines, Storage Accounts, Virtual Networks, and more. Each section contains "
        "a description of the service, a table of key resource attributes, and unique resource IDs."
    )

    doc.add_heading('Total Counts', level=1)
    doc.add_paragraph(f"Subscriptions: {counts['subscriptions']}")
    doc.add_paragraph(f"Resource Groups: {counts['resource_groups']}")
    doc.add_paragraph(f"Virtual Machines: {counts['virtual_machines']}")
    doc.add_paragraph(f"Disks: {counts['disks']}")
    doc.add_paragraph(f"Storage Accounts: {counts['storage_accounts']}")
    doc.add_paragraph(f"Virtual Networks: {counts['vnets']}")

    doc.add_heading('Table of Contents', level=1)
    toc = doc.add_paragraph()
    toc_run = toc.add_run()
    for i, section in enumerate(sections):
        toc_run.add_text(f"{i + 1}. {section['title']} ................... ")
        toc_run.add_text(f"Page {i + 6}")
        toc_run.add_break()

    doc.add_page_break()

    for section in sections:
        doc.add_heading(section['title'], level=1)
        doc.add_paragraph(section['description'])

        service_name = section['title'].replace("Service: ", "")
        headers = SERVICE_HEADERS.get(service_name, ["Name", "Resource Group", "Location", "Kind", "SKU", "Tags"])

        if service_name == "Azure Virtual Networks":
            headers = ["Name", "Resource Group", "Location", "Address Space", "Tags"]

        headers, content = remove_empty_columns(headers, section['content'])

        table = doc.add_table(rows=1, cols=len(headers))
        format_table_header(table, headers)

        for item in content:
            row_cells = table.add_row().cells
            for idx, header in enumerate(headers):
                row_cells[idx].text = item.get(header, 'N/A')

        set_table_borders(table)

        for item in section['content']:
            resource_id = item.get('ID', 'N/A')
            logging.info(f"Resource ID: {resource_id}")
            id_paragraph = doc.add_paragraph()
            id_run = id_paragraph.add_run(f"ID: {resource_id}")
            id_run.bold = True

        doc.add_paragraph("\n")

    doc.save(filename)
    logging.info(f"Document saved as {filename}")

def main():
    logging.info("Starting the As-Built Document generation process.")
    subscription_ids = os.getenv('AZURE_SUBSCRIPTION_IDS', '5514d116-97eb-4cfc-927f-b03826fcc9cc').split(',')
    resource_clients, network_clients = load_azure_data(subscription_ids)
    all_resources = fetch_resources(resource_clients)
    network_details = fetch_network_details(network_clients)
    sections, counts = process_resource_data(all_resources, network_details)
    generate_document(sections, counts)
    logging.info("As-Built Document generation process completed.")

if __name__ == "__main__":
    main()
```

## Usage

1. Ensure the required environment variables are set.
2. Run the script:

```bash
python script_name.py
```

This will generate a Word document named `asbuilt.docx` with detailed information about your Azure resources.
