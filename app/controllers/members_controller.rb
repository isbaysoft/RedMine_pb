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

class MembersController < ApplicationController
  model_object Member
  before_filter :find_model_object, :except => [:new, :autocomplete_for_member]
  before_filter :find_project_from_association, :except => [:new, :autocomplete_for_member]
  before_filter :find_project, :only => [:new, :autocomplete_for_member]
  before_filter :authorize

  def new
    members = []
    if params[:member] && request.post?
      attrs = params[:member].dup

#      Join LDAP users to member[:user_ids]
      attrs[:user_ids] ||= []
      params[:ldap][:user_ids].map do |dn|
        user_data = ActiveSupport::JSON.decode(dn)
        attrs[:user_ids].push create_ldap_user(user_data)
      end unless params[:ldap].blank?

      if (user_ids = attrs.delete(:user_ids))
        user_ids.each do |user_id|
          members << Member.new(attrs.merge(:user_id => user_id))
        end
      else
        members << Member.new(attrs)
      end
      @project.members << members
    end
    respond_to do |format|
      if members.present? && members.all? {|m| m.valid? }

        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }

        format.js { 
          render(:update) {|page| 
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page << 'hideOnLoad()'
            members.each {|member| page.visual_effect(:highlight, "member-#{member.id}") }
          }
        }
      else

        format.js {
          render(:update) {|page|
            errors = members.collect {|m|
              m.errors.full_messages
            }.flatten.uniq
            page.alert(l(:notice_failed_to_save_members, :errors => errors.join(', ')))
          }
        }
        
      end
    end
  end
  
  def edit
    if request.post? and @member.update_attributes(params[:member])
  	 respond_to do |format|
        format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
        format.js { 
          render(:update) {|page| 
            page.replace_html "tab-content-members", :partial => 'projects/settings/members'
            page << 'hideOnLoad()'
            page.visual_effect(:highlight, "member-#{@member.id}")
          }
        }
      end
    end
  end

  def destroy
    if request.post? && @member.deletable?
      @member.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :tab => 'members', :id => @project }
      format.js { render(:update) {|page|
          page.replace_html "tab-content-members", :partial => 'projects/settings/members'
          page << 'hideOnLoad()'
        }
      }
    end
  end
  
  def autocomplete_for_member
    @principals = Principal.active.like(params[:q]).find(:all, :limit => 100) - @project.principals
    render :layout => false
  end

protected

  def create_ldap_user( user_data )
    unless User.exists?(['login = ?',user_data['login']])
      user = User.new
      user.login = user_data['login'] unless user_data['login'].nil?
      user.mail = user_data['mail'] unless user_data['mail'].nil?
      user.firstname = user_data['firstname'] unless user_data['firstname'].nil?
      user.lastname = user_data['lastname'] unless user_data['lastname'].nil?
      user.register
      user.activate
      user.last_login_on = Time.now
      user.auth_source_id = user_data['auth_source_id']
      user.save
    else
      user = User.find_by_login(user_data['login'])
    end
    user[:id].to_i
  end

end
