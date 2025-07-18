.PHONY: init plan apply destroy lint fmt validate clean

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan

# Apply Terraform changes
apply:
	terraform apply

# Destroy Terraform infrastructure
destroy:
	terraform destroy

# Format Terraform files
fmt:
	terraform fmt -recursive

# Validate Terraform configuration
validate:
	terraform validate

# Run TFLint
lint:
	tflint --init
	tflint --recursive

# Run all checks
check: fmt validate lint

# Clean up
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*

# Security scan with tfsec
security:
	tfsec .

# Run all quality checks
quality: fmt validate lint security

# Development workflow
dev: init fmt validate lint plan