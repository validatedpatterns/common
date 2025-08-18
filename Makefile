MAKEFLAGS += --no-print-directory
# ANSIBLE_RUN = ansible-playbook $(EXTRA_PLAYBOOK_OPTS) -vvv
ANSIBLE_RUN = ANSIBLE_STDOUT_CALLBACK=null ansible-playbook $(EXTRA_PLAYBOOK_OPTS)

##@ Pattern Common Tasks

.PHONY: help
help: ## This help message
	@echo "Pattern: $(NAME)"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^(\s|[a-zA-Z_0-9-])+:.*?##/ { printf "  \033[36m%-35s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

#  Makefiles in the individual patterns should call these targets explicitly
#  e.g. from industrial-edge: make -f common/Makefile show
.PHONY: show
show: ## show the starting template without installing it
	@$(ANSIBLE_RUN) rhvp.cluster_utils.show

preview-all: ## (EXPERIMENTAL) Previews all applications on hub and managed clusters
	@$(ANSIBLE_RUN) rhvp.cluster_utils.preview_all

preview-%:
	@$(ANSIBLE_RUN) -e app=$* rhvp.cluster_utils.preview

.PHONY: operator-deploy
operator-deploy operator-upgrade: ## validates the pattern repo and installs via the pattern-install chart
	@$(ANSIBLE_RUN) rhvp.cluster_utils.operator_deploy

.PHONY: load-secrets
load-secrets: ## loads the secrets into the backend determined by values-global setting
	@$(ANSIBLE_RUN) rhvp.cluster_utils.process_secrets

.PHONY: legacy-load-secrets
legacy-load-secrets: ## loads the secrets into vault (only)
	@$(ANSIBLE_RUN) -t push_secrets rhvp.cluster_utils.vault

.PHONY: secrets-backend-vault
secrets-backend-vault: ## Edits values files to use default Vault+ESO secrets config
	@$(ANSIBLE_RUN) -e secrets_backing_store=vault rhvp.cluster_utils.configure_secrets_backend

.PHONY: secrets-backend-kubernetes
secrets-backend-kubernetes: ## Edits values file to use Kubernetes+ESO secrets config
	@$(ANSIBLE_RUN) -e secrets_backing_store=kubernetes rhvp.cluster_utils.configure_secrets_backend

.PHONY: secrets-backend-none
secrets-backend-none: ## Edits values files to remove secrets manager + ESO
	@$(ANSIBLE_RUN) -e secrets_backing_store=none rhvp.cluster_utils.configure_secrets_backend

.PHONY: load-iib
load-iib: ## CI target to install Index Image Bundles
	@$(ANSIBLE_RUN) rhvp.cluster_utils.iib_ci

.PHONY: token-kubeconfig
token-kubeconfig: ## Create a local ~/.kube/config with password (not usually needed)
	@$(ANSIBLE_RUN) rhvp.cluster_utils.write_token_kubeconfig

##@ Validation Tasks

# If the main repoUpstreamURL field is set, then we need to check against
# that and not target_repo
.PHONY: validate-origin
validate-origin: ## verify the git origin is available
	@$(ANSIBLE_RUN) rhvp.cluster_utils.validate_origin

.PHONY: validate-cluster
validate-cluster: ## Do some cluster validations before installing
	@$(ANSIBLE_RUN) rhvp.cluster_utils.validate_cluster

.PHONY: validate-schema
validate-schema: ## validates values files against schema in common/clustergroup
	@$(ANSIBLE_RUN) rhvp.cluster_utils.validate_schema

.PHONY: validate-prereq
validate-prereq: ## verify pre-requisites
	@$(ANSIBLE_RUN) rhvp.cluster_utils.validate_prereq

.PHONY: argo-healthcheck
argo-healthcheck: ## Checks if all argo applications are synced
	@$(ANSIBLE_RUN) rhvp.cluster_utils.argo_healthcheck

##@ Test and Linters Tasks

.PHONY: qe-tests
qe-tests: ## Runs the tests that QE runs
	@set -e; if [ -f ./tests/interop/run_tests.sh ]; then \
		pushd ./tests/interop; ./run_tests.sh; popd; \
	else \
		echo "No ./tests/interop/run_tests.sh found skipping"; \
	fi

.PHONY: super-linter
super-linter: ## Runs super linter locally
	rm -rf .mypy_cache
	podman run -e RUN_LOCAL=true -e USE_FIND_ALGORITHM=true	\
					-e VALIDATE_ANSIBLE=false \
					-e VALIDATE_BASH=false \
					-e VALIDATE_CHECKOV=false \
					-e VALIDATE_DOCKERFILE_HADOLINT=false \
					-e VALIDATE_JSCPD=false \
					-e VALIDATE_JSON_PRETTIER=false \
					-e VALIDATE_MARKDOWN_PRETTIER=false \
					-e VALIDATE_KUBERNETES_KUBECONFORM=false \
					-e VALIDATE_PYTHON_PYLINT=false \
					-e VALIDATE_SHELL_SHFMT=false \
					-e VALIDATE_TEKTON=false \
					-e VALIDATE_YAML=false \
					-e VALIDATE_YAML_PRETTIER=false \
					$(DISABLE_LINTERS) \
					-v $(PWD):/tmp/lint:rw,z \
					-w /tmp/lint \
					ghcr.io/super-linter/super-linter:slim-v7

.PHONY: deploy upgrade legacy-deploy legacy-upgrade
deploy upgrade legacy-deploy legacy-upgrade:
	@echo "UNSUPPORTED TARGET: please switch to 'operator-deploy'"; exit 1
