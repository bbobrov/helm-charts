SYSLOG5424PRINTASCII [!-~]+

SYSLOGBASE2 (?:%{SYSLOGTIMESTAMP:timestamp}|%{TIMESTAMP_ISO8601:timestamp8601}) (?:%{SYSLOGFACILITY} )?%{SYSLOGHOST:logsource}+(?: %{SYSLOGPROG}:|)
SYSLOGPAMSESSION %{SYSLOGBASE} (?=%{GREEDYDATA:message})%{WORD:pam_module}\(%{DATA:pam_caller}\): session %{WORD:pam_session_state} for user %{USERNAME:username}(?: by %{GREEDYDATA:pam_by})?

CRON_ACTION [A-Z ]+
CRONLOG %{SYSLOGBASE} \(%{USER:user}\) %{CRON_ACTION:action} \(%{DATA:message}\)

SYSLOGLINE %{SYSLOGBASE2} %{GREEDYDATA:message}

# IETF 5424 syslog(8) format (see http://www.rfc-editor.org/info/rfc5424)
SYSLOG5424PRI <%{NONNEGINT:syslog5424_pri}>
SYSLOG5424SD \[%{DATA}\]+
SYSLOG5424BASE %{SYSLOG5424PRI}%{NONNEGINT:syslog5424_ver} +(?:%{TIMESTAMP_ISO8601:syslog5424_ts}|-) +(?:%{IPORHOST:syslog5424_host}|-) +(-|%{SYSLOG5424PRINTASCII:syslog5424_app}) +(-|%{SYSLOG5424PRINTASCII:syslog5424_proc}) +(-|%{SYSLOG5424PRINTASCII:syslog5424_msgid}) +(?:%{SYSLOG5424SD:syslog5424_sd}|-|)

SYSLOG5424LINE %{SYSLOG5424BASE} +%{GREEDYDATA:syslog5424_msg}


# CISCO Syslog Pattern
SYSLOGCISCOTIMESTAMP [0-9]{4} [A-Z][a-z]{2}\s{1,2}\d{1,2} \d{2}:\d{2}:\d{2} [A-Z]{3}
SYSLOGCISCOFACILITY [%A-Z]+
SYSLOGCISCOSEVERITY \d
SYSLOGCISCOCODE [A-Z_]+
SYSLOGCISCOSTRING %{SYSLOGCISCOFACILITY:syslogcisco_facility}-%{SYSLOGCISCOSEVERITY:syslogcisco_severity}-%{SYSLOGCISCOCODE:syslogcisco_code}
