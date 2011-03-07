# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module AuthSourcesHelper
  def ldap_users_check_box_tags(name, ldap_users)
    s = ''
    ldap_users.map do |ldap|
      ldap.map do |user|
        username = "#{user[:firstname]} #{user[:lastname]}"
        s << "<label>#{ check_box_tag name, user.to_json, false } #{h username}</label>\n"
      end
    end if @ldap_users.present?
    s
  end
end
