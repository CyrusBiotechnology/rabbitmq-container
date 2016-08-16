#!/bin/bash

# Try to extract the hostname, first from RABBITMQ_NODENAME, then NODENAME
_NAME=`echo "$RABBITMQ_NODENAME" | awk -F '@' '{print $2}'`
[ -n "$_NAME" ] || NAME=`echo "$NODENAME" | awk -F '@' '{print $2}'`

if [ -n "$_NAME" ]; then
    # NAME is not empty. Is it in /etc/hosts?
    if [ -z "$(grep $_NAME /etc/hosts)" ]; then
        echo "127.0.0.1 $_NAME" >> /etc/hosts
    fi
fi

# Since Rabbit doesn't run as root, we create the logfile and chown it if required
if [ -n "${RABBITMQ_LOGS//-}" ]; then
		if [ ! -d "$(dirname ${RABBITMQ_LOGS})" ]; then
				echo "creating rabbitmq logs directory"
		    mkdir -p `dirname ${RABBITMQ_LOGS}`
		fi
		if [ ! -e "${RABBITMQ_LOGS}" ]; then
				echo "creating rabbitmq log"
		 		touch "$RABBITMQ_LOGS"
		fi

		echo "changing ownership of $(dirname ${RABBITMQ_LOGS}) to 'rabbitmq'"
		chown -R rabbitmq "$(dirname ${RABBITMQ_LOGS})"
		#echo "changing permissions to 777"
		#chmod 777 "${RABBITMQ_LOGS}"
		ls -al "$(dirname ${RABBITMQ_LOGS})"
fi

if [ "$RABBITMQ_ERLANG_COOKIE" ]; then
	cookieFile='/var/lib/rabbitmq/.erlang.cookie'
	if [ -e "$cookieFile" ]; then
		if [ "$(cat "$cookieFile" 2>/dev/null)" != "$RABBITMQ_ERLANG_COOKIE" ]; then
			echo >&2
			echo >&2 "warning: $cookieFile contents do not match RABBITMQ_ERLANG_COOKIE"
			echo >&2
		fi
	else
		echo "$RABBITMQ_ERLANG_COOKIE" > "$cookieFile"
		chmod 600 "$cookieFile"
		chown rabbitmq "$cookieFile"
	fi
fi

if [ "$1" = 'rabbitmq-server' ]; then
	configs=(
		# https://www.rabbitmq.com/configure.html
		default_vhost
		default_user
		default_pass
	)

	haveConfig=
	for conf in "${configs[@]}"; do
		var="RABBITMQ_${conf^^}"
		val="${!var}"
		if [ "$val" ]; then
			haveConfig=1
			break
		fi
	done

	if [ "$haveConfig" ]; then
		cat > /etc/rabbitmq/rabbitmq.config <<-'EOH'
			[
			  {rabbitmq_management, [{rates_mode, none}]},
			  {rabbit,
			    [
		EOH
		for conf in "${configs[@]}"; do
			var="RABBITMQ_${conf^^}"
			val="${!var}"
			[ "$val" ] || continue
			cat >> /etc/rabbitmq/rabbitmq.config <<-EOC
			      {$conf, <<"$val">>},
			EOC
		done
		cat >> /etc/rabbitmq/rabbitmq.config <<-'EOF'
			      {loopback_users, []}
			    ]
			  }
			].
		EOF
	fi

	chown -R rabbitmq /var/lib/rabbitmq
	set -- gosu rabbitmq "$@"
fi

exec "$@"
