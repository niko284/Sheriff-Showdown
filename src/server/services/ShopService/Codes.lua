--!strict

type Code = {
	ExpirationTime: number?,
	Redeem: (Player: Player) -> (),
}

return {} :: { [string]: Code }
