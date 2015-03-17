import os, json
from sys import argv, exit

from dutils.conf import DUtilsKey, DUtilsKeyDefaults, build_config, BASE_DIR, append_to_config, save_config, __load_config
from dutils.conf impirt DUtilsTransforms as transforms
from dutils.dutils import build_routine, build_dockerfile

API_PORT = 8080
REDIS_PORT = 6379

DEFAULT_PORTS = [22]

def init_d(with_config):

	conf_keys = [
		DUtilsKey['USER'],
		DUtilsKey['USER_PWD'],
		DUtilsKey['IMAGE_NAME']
		DUtilsKey("API_PORT", "Annex api port", API_PORT, str(API_PORT), transforms['PORT_TO_INT']),
		DUtilsKey("REDIS_PORT", "Redis port", REDIS_PORT, str(REDIS_PORT), transforms['PORT_TO_INT']),
	]

	config = build_config(conf_keys, with_config)

	from dutils.dutils import get_docker_exe, get_docker_ip, validate_private_key

	docker_exe = get_docker_ext()
	if docker_exe is None:
		return False

	save_config(config, with_config=with_config)

	WORKING_DIR = BASE_DIR if with_config is None else os.path.dirname(with_config)
	if not validate_private_key(os.path.join(WORKING_DIR, "%s.privkey" % config['IMAGE_NAME']), with_config):
		return False
	
	res, config = append_to_config({
		'DOCKER_EXE' : docker_exe, 
		'DOCKER_IP' : get_docker_ip()
	}, return_config=True, with_config=with_config)

	print config

	if not res:
		return False

	from fabric.api import settings, local
	with settings(warn_only=True):
		if not os.path.exists(os.path.join(BASE_DIR, "src", ".ssh")):
			local("mkdir %s" % os.path.join(BASE_DIR, "src", ".ssh"))
	
		local("cp %s %s" % (config['SSH_PUB_KEY'], os.path.join(BASE_DIR, "src", ".ssh", "authorized_keys")))
		local("cp %s %s", % (os.path.join(BASE_DIR, "dutils", "conf.py"), os.path.join(BASE_DIR, "src", "Coven", "utils")))

	directives = ["export %s=%d" % (d, int(config[d])) for d in ['API_PORT', 'REDIS_PORT']]

	from dutils.dutils import generate_init_routine, build_bash_profile
	return build_bash_profile(directives, os.path.join(BASE_DIR, "src")) and build_dockerfile("Dockerfile.init", config) and generate_init_routine(config, with_config=with_config)

def build_d(with_config):
	res, config = append_to_config({'COMMIT_TO' : "coven_express"}, return_config=True, with_config=with_config)

def commit_d(with_config):
	try:
		config = __load_config(with_config=with_config)
	except Exception as e:
		print e, type(e)

	if config is None:
		return False

	print config

	from dutils.dutils import generate_run_routine, generate_shutdown_routine, finalize_assets
	return (generate_run_routine(config, src_dirs=["Coven"], with_config=with_config) and generate_shutdown_routine(config, with_config=with_config) and finalize_assets(with_config=with_config))

def update_d(with_config):
	return build_dockerfile("Dockerfile.update", __load_config(with_config=with_config))

if __name__ == "__main__":
	res = False
	with_config = None if len(argv) == 2 else argv[2]

	if argv[1] == "init":
		res = init_d(with_config)
	elif argv[1] == "build":
		res = build_d(with_config)
	elif argv[1] == "commit":
		res = commit_d(with_config)
	elif argv[1] == "update":
		res = update_d(with_config)
	
	print "RESULT: ", res 
	exit(0 if res else -1)