# Table of contents

- [Purpose of the tiny ocm installer](#purpose-of-the-tiny-ocm-installer)
- [Setup summary ( simple case )](#setup-summary--simple-case-)
- [Essential spiff++ background information](#essential-spiff-background-information)
- [Workflow](#workflow)
- [Providing template configs to users](#providing-template-configs-to-users)


# Purpose of the tiny ocm installer 

The idea is that someone with :
- docker 
- ocm cli 
- your appropriately constructed component 

can run install code that you placed in your OCM component version using a command like :

```
ocm bootstrap cv -c credentials-file -o output-dir -p parameter-file my-install-action https://registry//sap.com/sac/loregi:1.0.0 my-toi-installer-resource 
```

Where 
- `ocm bootstrap cv` is the OCM cli subcommand for running install code 
- `credentials-file` is a file with credentials the install process may need 
- `output-dir` is a destination for any output files the install code may need to provide to the person running the command.   ( e.g. logs or generated tokens ) 
- `parameter-file` contains input parameters for the install code
- `my-install-action` is a subcommand to the install executable.    When you write your install executable you decide what commands it supports
- `https://registry//sap.com/sac/loregi:1.0.0` is the location of your OCM component version 
- `my-toi-installer-resource` is the name of a resource in your component version that has the type `toiPackage`

Your install code will run in a docker container on the system where the above commmand was executed.

# Setup summary ( simple case ) 

Your OCM component version must contain an oci image resource with the following layout 
```
/
└── toi
    ├── inputs
    │   ├── config      configuration from package specification
    │   ├── ocmrepo     OCM filesystem repository containing the complete
    │   │               component version of the package
    │   └── parameters  merged complete parameter file
    ├── outputs
    │   ├── <out>       any number of arbitrary output data provided
    │   │               by executor
    │   └── ...
    └── run             good practice: typical location for the executed command
```

Note : 
- The inputs directory will be filled in by the  OCM cli when it runs your installer in a docker container 
- If your installer code generates any content  that the person running the installer will need then it should place those files in the outputs directory.   The OCM cli will copy the contents out to the location specified to the OCM cli
- `run` is your install executable

Your OCM component version must also contain a resource of type `toiPackage`.   This is a yaml file and the format is covered [here](https://ocm.software/docs/cli-reference/help/toi-bootstrapping/#the-codetoipackagecode-resource)

You of course need to provide documentation to the operators who will be running your install.

# Essential Spiff++ background information

[Spiff++](https://github.com/mandelsoft/spiff) is a yaml ( and json? ) templating language similar to [helm](https://helm.sh/).  Major differences are 
- Spiff++ is only for templating.   It doesn't perform kubernetes installs
- Spiff+++ template files are always valid yaml, unlike `helm` templates

A command like 

```spiff++ merge a.yaml b.yaml c.yaml```

merges c.yaml into b.yaml and then merges the result of that merge into a.yaml.   This is, very roughly, similar to how values files are merged together in the `helm` command line

```helm template -f a.yaml -f b.yaml -f c.yaml mychart```

Critical sections of the `Spiff++`documentation are  
- The section [Bringing it all together](https://github.com/mandelsoft/spiff?tab=readme-ov-file#bringing-it-all-together)
- The section [Useful to know](https://github.com/mandelsoft/spiff?tab=readme-ov-file#useful-to-know).   In particular the first bullet point `The auto merge never adds nodes to existing structures`
- The explanation for [((foo.bar.[1].baz))](https://github.com/mandelsoft/spiff?tab=readme-ov-file#-foobar1baz-).   This notes that references are always to nodes in the current template or stub.   So with the command 

    ```spiff++ merge a.yaml b.yaml```

    If `b.yaml` is 

    ```b: boo```

    then in `a.yaml` to refernece b you need either to reference it as is :

    ```
    a: blah
    b: ~
    ```

    or to bring the value into a temporary node and then reference the value in the temporary node :

    ```
    a: (( b ))  # This will have the value of b in b.yaml
    b: (( &tempoarary )) # This node will be omitted from final output
    ```

    or access it through the `stub` function 

    ```
    a: (( stub(b) ))

Note that `Spiff++` discards some notes, such as those marked as `(( &temporary ))`.   For more detail refer to the [documentation](https://github.com/mandelsoft/spiff).

# Workflow 

1. Determine and load credentials file.   Will either be passed via -c on command line or will be TOICredentials in the current dir.
    The file is just an ocm configfile where only the credentials will be used 

2. Make executor config from:
   - toiExecutor.configTemplate.  This is a spiff template
   - toiPackage.executors[].config.  Despite what OCM documentation says, this is a spiff template
   - toiExecutor.templateLibraries.  These are references to resources in the component version
   - toiExecutor.schema.  This is a reference to a json schema in the component version
  
   Basically it is like `OCM` is running the command 

   ```
   spiff++ merge toiExecutor.configTemplate toiPackage.executors[].config toiExecutor.templateLibraries...
   ```

   and then afterwards validating the result against the json schema `toiExecutor.schema` 

3. Process Credential requests of [toiPackage](https://ocm.software/docs/cli-reference/help/toi-bootstrapping/#the-codetoipackagecode-resource) and [toiExecutor](https://ocm.software/docs/cli-reference/help/toi-bootstrapping/#the-codetoiexecutorcode-resource)

    i.   Isolate those toiPackage credential requests which are named in toiPackage.executors[].credentialMapping 

	ii.  Make sure toiExecutor's requests can be satisfied by toiPackage's mapped requests ( exist and have correct properties ) 
	
	If there is a toiPackage.executors[].credentialMapping then really it is toiPackage's requests that get used.
	Otherwise toiExecutor's requests get used. 
	
	This process builds a set of CredentialRequests and the mappings.
	
4. Resolve credential requests collected from previous step

    This outputs [ocmconfig](https://github.com/open-component-model/ocm/blob/main/docs/reference/ocm_configfile.md) yaml and a map map[string]string where :
	- the ocmconfig yaml just has the credentials data filled in with consumer 
	- The keys in them are the keys from the credentials field, which is `map[string]CredentialRequest`, 
	  and the values are the properties ( user name and password, or whatever ) of the associated 
	  credentials.
	  
	NOTE: This means in the documentation of your installer you must be clear about what the 
	credentials look like.    Perhaps this can be done with `ocm toi describe package [my package]` and the 'additional resources' which a user can extract using `ocm toi configuration bootstrap [my package]`
	
    
5. Make user config ( named params in code ) from 
    - toiPackage.configTemplate.  This is a spiff template
    - parameter passed on command line.  This is a spiff template even though documentation doesn't indicate this 
    - toiPackage.templateLibraries.  These are references to resources in the component version
    - toiPackage.schema.  This is a reference to a json schema in the component version
  
    NOTE: Process is very similar to #2 above.   However a difference is that these functions are made available to the spiff templates 
      - hasCredentials(string[,string])bool 
      - getCredentials(string[,string]) map[string}string | string 

    To be clear, the above functions take a string argument and an optional second string argument.  The first is the key from the credential request.   If the second argument is not passed then the expression is looking for, or retrieving, a map containing the properties, e.g. username and password, of specified credential.   If a second argument is passed then the functions look for, or retrieve, the proprety of the same name from the credential identified by the first argument.
  
6. perform 'parameter mapping' using 

    - toiPackage.executor[].parameterMapping 
    - user configuration output by from previous step ( step #5 ) 

   The process used is spiff processing similar to that in step 2 above.

7. Set up files for the executable in the executor image 

    - `/toi/inputs/ocmconfig`  Output from step #4 above
    - `/toi/inputs/parameters`  Output from step #6 above.  User supplied parameters after being mapped/spiffed 
    - `/toi/inputs/config`  Output from step #2.  Configuration after being spiffed 
    - `/toi/inputs/ocmrepo`  Component descriptor downloaded from source repository

8. Use docker to run a container with the arguments `[action] [component version]`.  The image will be the one named in the `imageRef` field of `toiExecutor`.   OCM assumes the image has an entry point defined.

9. Copy `/toi/outputs` from within the container to the current working directory or the location specified on the OCM command line.

## Simulating spiff++ operations of the workflow 

The script `scripts/simulateTOIWorkflowWithSpiffCLI.sh` simulates the spiff++ operations steps #2, #5 and #6 of the workflow described above.

Note there are a few aspects of it that are not realistic :
- In the simulation of step 2, `./toiPackage/toiPackageExecutorConfig.yaml`, which is part of the `toiPackage`, wouldn't have references to the libraries named in the `toiExecutor`.

- In the simulation of step 5, `./userInput/parametersFromCLI.yaml`, which is provided by the user on the commandline, wouldn't have references to the libraries named in the `toiPackage`.

- In the simulation of step 5 the lambda expression defined in `getCredentials.yaml` used to simulate the [getCredentials](https://ocm.software/docs/cli-reference/help/toi-bootstrapping/#input-mapping-for-executors) function that OCM defines during spiff++ execution.



# Providing template configs to users

The OCM cli also supports a command of the form :
```
ocm bootstrap cfg -c credentials-file -p parameter-file https://registry//sap.com/sac/loregi:1.0.0 my-toi-installer-resource 
```

Other than the OCM subcommand, the elements of the above command line match that of the install.

This will extract any template/prototype install config files that you have supplied in your OCM component versoin.  The files are just normal resources within your component version.   However by naming them as `additionalResources` in your [toiPackage](https://ocm.software/docs/cli-reference/help/toi-bootstrapping/#the-codetoipackagecode-resource) resource the OCM cli knows to extract them when the user runs the `ocm bootstrap cfg` command.


