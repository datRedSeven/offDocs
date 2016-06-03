class Usermailer < ApplicationMailer
	default from: "admin@offdocs.com"

	def send_updates(user, update_list)
    	@user = user
    	@update_list = update_list
    	mail(to: @user.email, subject: 'Sample Email')
  	end
end
