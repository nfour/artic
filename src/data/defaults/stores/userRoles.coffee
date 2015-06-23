
module.exports =
	data: [
		{
			id		: 1
			name	: 'Super Admin'
			can:
				create:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

				read:
					admin			: true
					adminUsers		: true
					adminArticles	: true
					adminPages		: true
					adminNew		: true
					adminEdit		: true
					adminSettings	: true
					adminText		: true
					adminCategories	: true
					adminDashboard	: true

					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

				update:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

				delete:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

		}
		{
			id		: 2
			name	: 'Admin'
			can:
				create:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

				read:
					admin			: true
					adminUsers		: true
					adminArticles	: true
					adminPages		: true
					adminNew		: true
					adminEdit		: true
					adminSettings	: true
					adminText		: true
					adminCategories	: true
					adminDashboard	: true

					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

				update:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

				delete:
					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						users		: true
						articles	: true
						pages		: true
						comments	: true

		}
		{
			id		: 3
			name	: 'Editor'
			can:
				create:
					articles	: true
					pages		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

				read:
					admin			: true
					adminUsers		: true
					adminArticles	: true
					adminPages		: true
					adminNew		: true
					adminEdit		: true
					adminSettings	: true
					adminText		: true
					adminCategories	: true
					adminDashboard	: true

					users		: true
					userRoles	: true
					articles	: true
					pages		: true
					settings	: true
					text		: true
					comments	: true
					categories	: true
					tags		: true
					uploads		: true

				update:
					articles	: true
					pages		: true
					settings	: true
					text		: true
					categories	: true
					tags		: true
					uploads		: true

					owned:
						comments	: true

				delete:
					articles	: true
					pages		: true
					tags		: true
					uploads		: true

					owned:
						comments	: true
		}
		{
			id		: 4
			name	: 'Author'
			can:
				create:
					articles	: true
					pages		: true
					comments	: true
					tags		: true
					uploads		: true

				read:
					admin			: true
					adminArticles	: true
					adminPages		: true
					adminNew		: true
					adminEdit		: true
					adminDashboard	: true

					articles	: true
					pages		: true
					comments	: true
					tags		: true
					uploads		: true

				update:
					tags		: true
					uploads		: true

					owned:
						articles	: true
						pages		: true
						comments	: true

				delete:
					owned:
						articles	: true
						pages		: true
						comments	: true
		}
		{
			id		: 5
			name	: 'Pleb'
			can: {}

		}
	]
