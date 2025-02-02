input {
  udp {
    port => 5514
    type => esxi
  }
}
filter {
  if [type] == "esxi" and "FIREWALL_PKTLOG" in [message] {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{TIMESTAMP_ISO8601:timestamp}.%{IPORHOST}.FIREWALL_PKTLOG:.%{WORD:target_suffix}.%{WORD:af_value}.match.%{WORD:action}.+.%{WORD:direction}.%{INT:length}.%{WORD:protocol}.%{IP:src_ip}/%{INT:src_port}.*%{IP:dst_ip}/%{INT:dst_port}.([SEW]+ )?%{NOTSPACE:sg_id}"}
    }
    if "_grokparsefailure" in [tags] {
      drop { }
    }
    ruby {
      init => 'require "sequel"; $rc = Sequel.connect("jdbc:mysql://{{include "db_host_mysql" .}}/{{.Values.db_name}}?user={{ coalesce .Values.dbUser .Values.global.dbUser "root" }}&password={{ coalesce .Values.dbPassword .Values.global.dbPassword .Values.mariadb.root_password | required ".Values.mariadb.root_password is required!" }}")'
      code => '
      event_map = {"PASS" => "ACCEPT", "REJECT" => "DROP"}
      res = $rc[:logs].select(:target_id, :resource_id, :project_id).where(resource_type: "security_group").where(:enabled).where(event: [event_map[event.get("action")], "ALL"]).where(Sequel.like(:resource_id, event.get("sg_id") + "%")).where(Sequel.like(:target_id,"%" + event.get("target_suffix"))).first
      unless res.nil?
        event.set("port", res[:target_id])
        event.set("project", res[:project_id])
        event.set("security_group", res[:resource_id])
        event.remove("target_suffix")
        event.remove("sg_id")
        event.remove("message")
      else
        event.cancel
      end
      '
    }
  } else {
    drop { }
  }
}
output {
{{- if .Values.logger.persistence.enabled }}
 file {
   path => "/data/%{project}.log"
   codec => line { format => "%{timestamp} %{af_value} %{action} %{direction} len:%{length} proto:%{protocol} src_ip:%{src_ip} src_port:%{src_port} dst_ip:%{dst_ip} dst_port:%{dst_port} port:%{port} security_group:%{security_group}" }
 }
{{- else }}
  stdout { codec => rubydebug }
{{- end }}
}
