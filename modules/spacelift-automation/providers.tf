# Earlier versions of OpenTofu used empty provider blocks ("proxy provider configurations")
# for child modules to declare their need to be passed a provider configuration by their
# callers. That approach was ambiguous and is now deprecated.
#
# If you control this module, you can migrate to the new declaration syntax by removing all
# of the empty provider "spacelift" blocks and then adding or updating an entry like the
# following to the required_providers block of module.automation:
#     spacelift = {
#       source = "spacelift-io/spacelift"
#     }
