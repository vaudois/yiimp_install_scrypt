<?php

function yaamp_get_algos()
{
	/* Toggle Site Algos Here */
	return array(
		'sha256',
		'sha256csm',
		'sha256t',
		'sha512256d',
		'scrypt',
		'scryptn',
		'allium',
		'anime',
		'argon2',
		'argon2d250',
		'argon2d-dyn',
		'argon2d4096',
		'argon2d16000',
		'aergo',
		'balloon',
		'bastion',
		'bcd',
		'bitcore',
		'blake',
		'blakecoin',
		'blake2s',
		'bmw512',
		'cosa',
		'cpupower',
		'curvehash',
		'decred',
		'dedal',
		'deep',
		'heavyhash',
		'hmq1725',
		'honeycomb',
		'keccak',
		'keccakc',
		'jha',
		'hex',
		'hsr',
		'lbry',
		'lbk3',
		'luffa',
		'lyra2',
		'lyra2TDC',
		'lyra2v2',
		'lyra2v3',
		'lyra2z',
		'lyra2z330',
		'lyra2vc0ban',
		'neoscrypt',
		'nist5',
		'penta',
		'polytimos',
		'power2b',
		'quark',
		'qubit',
		'rainforest',
		'renesis',
		'c11',
		'x11',
		'x11evo',
		'x11k',
		'x11kvs',
		'x12',
		'x13',
		'x14',
		'x15',
		'x16r',
		'x16rt',
		'x16rv2',
		'x16s',
		'x17',
		'x18',
		'x20r',
		'x21s',
		'x22i',
		'x25x',
		'xevan',
		'geek',
		'gr',
		'groestl', // dmd-gr -m 256 (deprecated)
		'dmd-gr',
		'myr-gr',
		'm7m',
		'megabtx',
		'megamec',
		'mike',
		'minotaur',
		'minotaurx',
		'phi',
		'phi2',
		'phi5',
		'0x10',
		'pipe',
		'sib',
		'skein',
		'skein2',
		'skunk',
		'sonoa',
		'timetravel',
		'tribus',
		'a5a',
		'vanilla',
		'veltor',
		'velvet',
		'vitalium',
		'yescrypt',
		'yescryptR8',
		'yescryptR16',
		'yescryptR32',
		'yespower',
		'yespowerIC',
		'yespowerIOTS',
		'yespowerLITB',
		'yespowerLTNCG',
		'yespowerR16',
		'yespowerRES',
		'yespowerSUGAR',
		'yespowerTIDE',
		'yespowerURX',
		'yespowerMGPC',
		'yespowerARWN',
		'whirlpool',
		'zr5',
		
		'astralhash',
		'globalhash',
		'jeonghash',
		'padihash',
		'pawelhash',
		
	);
}

// Used for graphs and 24h profit
// GH/s for fast algos like sha256
function yaamp_algo_mBTC_factor($algo)
{
	switch($algo) {
	case 'sha256':
	case 'sha256t':
	case 'blake':
	case 'blakecoin':
	case 'blake2s':
	case 'decred':
	case 'keccak':
	case 'keccakc':
	case 'lbry':
	case 'power2b':
		return 0.001;
	case 'gr':
		return 0.001;
	case 'mike':
		return 0.001;
	case 'yespowerARWN':
		return 0.001;
	case 'vanilla':
		return 1000;
	default:
		return 1;
	}
}

// mBTC coef per algo
function yaamp_get_algo_norm($algo)
{
	global $configAlgoNormCoef;
	if (isset($configAlgoNormCoef[$algo]))
		return (float) $configAlgoNormCoef[$algo];

	$a = array(
		'sha256'	=> 1.0,
		'curvehash'	=> 1.0,
		'scrypt'	=> 1.0,
		'scryptn'	=> 1.0,
		'x11'		=> 1.0,
		'x13'		=> 1.0,
		'argon2'	=> 1.0,
		'argon2d250'	=> 1.0,
		'argon2d-dyn'	=> 1.0,
		'argon2d4096'	=> 1.0,
		'lyra2'		=> 1.0,
		'lyra2v2'	=> 1.0,
		'lyra2v3'	=> 1.0,
		'gr'		=> 0.001,
		'yespowerARWN'		=> 0.001,
		'myr-gr'	=> 1.0,
		'mike'		=> 0.001,
		'nist5'		=> 1.0,
		'neoscrypt'	=> 1.0,
		'quark'		=> 1.0,
		'qubit'		=> 1.0,
		'skein'		=> 1.0,
		'blake'		=> 1.0,
		'keccak'	=> 1.0,
		'skein2'	=> 1.0,
		'velvet'	=> 1.0,
		'whirlpool'	=> 1.0,
		'power2b'	=> 0.001,
		'yescrypt'	=> 1.0,
		'yescryptR8'	=> 1.0,
		'yescryptR16'	=> 1.0,
		'yescryptR32'	=> 1.0,
		'zr5'		=> 1.0,
	);

	if(!isset($a[$algo]))
		return 1.0;

	return $a[$algo];
}

function getAlgoColors($algo)
{
	$a = array(
		'sha256'	=> '#d0d0a0',
		'sha256csm'	=> '#d0d0a0',
		'sha256t'	=> '#d0d0f0',
		'sha512256d'	=> '#d0d0a0',
		'scrypt'	=> '#c0c0e0',
		'neoscrypt'	=> '#a0d0f0',
		'scryptn'	=> '#d0d0d0',
		'c11'		=> '#a0a0d0',
		'cosa'		=> '#a0a0d0',
		'decred'	=> '#f0f0f0',
		'dedal'		=> '#f0f0f0',
		'deep'		=> '#e0ffff',
		'x11'		=> '#f0f0a0',
		'x11evo'	=> '#c0f0c0',
		'x11k'		=> '#f0f0a0',
		'x11kvs'	=> '#f0f0a0',
		'x12'		=> '#ffe090',
		'x13'		=> '#ffd880',
		'bcd'		=> '#ffd880',
		'x14'		=> '#f0c080',
		'x15'		=> '#f0b080',
		'x16r'		=> '#f0b080',
		'x16rt'		=> '#f0b080',
		'x16rv2'	=> '#f0b080',
		'x16s'		=> '#f0b080',
		'x17'		=> '#f0b0a0',
		'x18'		=> '#f0b0a0',
		'x20r'		=> '#f0b0a0',
		'x21s'		=> '#f0b0a0',
		'x22i'		=> '#f0f0a0',
		'x25x'		=> '#f0f0a0',
		'xevan'         => '#f0b0a0',
		'allium'	=> '#80a0d0',
		'anime'		=> '#80a0d0',
		'argon2'	=> '#e0d0e0',
		'argon2d250'	=> '#e0d0e0',
		'argon2d-dyn'	=> '#e0d0e0',
		'argon2d4096'	=> '#e0d0e0',
		'argon2d16000'	=> '#e0d0e0',
		'aergo'		=> '#e0d0e0',
		'bastion'	=> '#e0b0b0',
		'balloon'	=> '#e0b0b0',
		'blake'		=> '#f0f0f0',
		'blakecoin'	=> '#f0f0f0',
		'bmw512'	=> '#f0f0f0',
		'curvehash'	=> '#d0a0a0',
		'geek'		=> '#d0a0a0',
		'gr'		=> '#80a0d0',
		'groestl'	=> '#d0a0a0',
		'jha'		=> '#a0d0c0',
		'dmd-gr'	=> '#a0c0f0',
		'myr-gr'	=> '#a0c0f0',
		'hmq1725'	=> '#ffa0a0',
		'hsr'		=> '#aa70ff',
		'keccak'	=> '#c0f0c0',
		'keccakc'	=> '#c0f0c0',
		'heavyhash'	=> '#c0f0c0',
		'hex'		=> '#c0f0c0',
		'honeycomb'		=> '#c0f0c0',
		'lbry'		=> '#b0d0e0',
		'luffa'		=> '#a0c0c0',
		'm7m'		=> '#d0a0a0',
		'megabtx'	=> '#d0f0a0',
		'megamec'	=> '#d0f0a0',
		'mike'		=> '#d0f0a0',
		'minotaur'	=> '#d0f0a0',
		'minotaurx'	=> '#d0f0a0',
		'penta'		=> '#80c0c0',
		'nist5'		=> '#c0e0e0',
		'quark'		=> '#c0c0c0', 
		'qubit'		=> '#d0a0f0',
		'rainforest'	=> '#d0f0a0', 
		'renesis'	=> '#f0b0a0',
		'lyra2'		=> '#80a0f0',
		'lyra2TDC'		=> '#80a0f0',
		'lyra2v2'	=> '#80c0f0',
		'lyra2v3'	=> '#80c0f0',
		'lyra2vc0ban'	=> '#80c0f0',
		'lyra2z'	=> '#80b0f0',
		'lyra2z330'	=> '#80b0f0',
		'phi'		=> '#a0a0e0',
		'phi2'		=> '#a0a0e0',
		'phi5'		=> '#aba0e0',
		'0x10'	=> '#aba0e0',
		'pipe'		=> '#a0a0e0',
		'polytimos'	=> '#dedefe',
		'power2b'	=> '#e2d0d2',
		'sib'		=> '#a0a0c0',
		'skein'		=> '#80a0a0',
		'skein2'	=> '#c8a060',
		'sonoa'		=> '#c8a060',
		'timetravel'	=> '#f0b0d0',
		'bitcore'	=> '#f790c0',
		'skunk'		=> '#dedefe',
		'tribus'	=> '#c0d0d0',
		'a5a'		=> '#f0f0f0',
		'vanilla'	=> '#f0f0f0',
		'velvet'	=> '#aac0cc',
		'vitalium'	=> '#f0b0a0',
		'whirlpool'	=> '#d0e0e0',
		'yescrypt'	=> '#e0d0e0',
		'yescryptR8'	=> '#e0d0e0',
		'yescryptR16'	=> '#e0d0e0',
		'yescryptR32'	=> '#e0d0e0',
		'yespower' 		=> '#e2d0d2',
		'yespowerIC' 	=> '#e2d0d2',
		'yespowerIOTS' 	=> '#e2d0d2',
		'yespowerLITB' 	=> '#e2d0d2',
		'yespowerLTNCG' 	=> '#e2d0d2',
		'yespowerR16' 	=> '#e2d0d2',
		'yespowerRES' 	=> '#e2d0d2',
		'yespowerSUGAR' 	=> '#e2d0d2',
		'yespowerTIDE' 	=> '#e2d0d2',
		'yespowerURX' 	=> '#e2d0d2',
		'yespowerMGPC' 	=> '#e2d0d2',
		'yespowerARWN' 	=> '#e2d0d2',
		'cpupower' 	=> '#e2d0d2',
		'zr5'		=> '#d0b0d0',
		'lbk3'		=> '#809aef',
		'lyra2'		=> '#80a0f0',
		
		'astralhash' => '#e2d0d2',
		'globalhash' => '#e2d0d2',
		'jeonghash' => '#e2d0d2',
		'padihash' => '#e2d0d2',
		'pawelhash' => '#e2d0d2',
		

		'MN'		=> '#ffffff', // MasterNode Earnings
		'PoS'		=> '#ffffff'  // Stake
	);

	if(!isset($a[$algo]))
		return '#ffffff';

	return $a[$algo];
}

function getAlgoPort($algo)
{
	$a = array(
		'sha256'	=> 3333,
		'sha256csm'	=> 3340,
		'sha256t'	=> 3339,
		'sha512256d'	=> 7086,
		'lbry'		=> 3334,
		'scrypt'	=> 3433,
		'timetravel'	=> 3555,
		'bitcore'	=> 3556,
		'balloon'	=> 5100,
		'bcd'		=> 3643,
		'bmw512'	=> 5787,
		'c11'		=> 3573,
		'cosa'		=> 3574,
		'curvehash'	=> 3343,
		'dedal'		=> 8833,
		'deep'		=> 3535,
		'x11'		=> 3533,
		'x11evo'	=> 3553,
		'x11k'		=> 3534,
		'x11kvs'	=> 3536,
		'x12'		=> 3233,
		'x13'		=> 3633,
		'x15'		=> 3733,
		'x16r'		=> 3636,
		'x16rt'		=> 7220,
		'x16rv2'	=> 3637,
		'x16s'		=> 3663,
		'x17'		=> 3737,
		'x18'		=> 3738,
		'x20r'		=> 4300,
		'x21s'		=> 3323,
		'x22i'		=> 4200,
		'x25x'		=> 4210,
		'aergo'     => 3691,
		'xevan'		=> 3739,
		'hmq1725'	=> 3747,
		'nist5'		=> 3833,
		'x14'		=> 3933,
		'geek'		=> 3692,
		'gr'		=> 7070,
		'quark'		=> 4033,
		'whirlpool'	=> 4133,
		'neoscrypt'	=> 4233,
		'anime'		=> 4230,
		'argon2'	=> 4234,
		'argon2d250'	=> 4238,
		'argon2d-dyn'	=> 4239,
		'argon2d4096'	=> 4240,
		'argon2d16000'	=> 4241,
		'scryptn'	=> 4333,
		'allium'	=> 4443,
		'lbk3'		=> 5522,
		'lyra2'		=> 4433,
		'lyra2TDC'	=> 4434,
		'lyra2v2'	=> 4533,
		'lyra2v3'	=> 4550,
		'lyra2vc0ban'	=> 4563,
		'lyra2z'	=> 4553,
		'lyra2z330'	=> 4555,
		'jha'		=> 4633,
		'qubit'		=> 4733,
		'zr5'		=> 4833,
		'skein'		=> 4933,
		'sib'		=> 5033,
		'sonoa'		=> 8733,
		'keccak'	=> 5133,
		'keccakc'	=> 5134,
		'heavyhash'	=> 5136,
		'hex'		=> 5135,
		'honeycomb'	=> 7777,
		'skein2'	=> 5233,
		//'groestl'	=> 5333,
		'dmd-gr'	=> 5333,
		'myr-gr'	=> 5433,
		'zr5'		=> 5533,
		// 5555 to 5683 reserved
		'blake'		=> 5733,
		'blakecoin'	=> 5743,
		'cpupower'	=> 4250,
		'decred'	=> 3252,
		'vanilla'	=> 5755,
		'blake2s'	=> 5766,
		'penta'		=> 5833,
		'rainforest'	=> 7443,
		'renesis' => 5252,
		'luffa'		=> 5933,
		'm7m'		=> 6033,
		'veltor'	=> 5034,
		'velvet'	=> 6133,
		'vitalium'	=> 3233,
		'yescrypt'	=> 6233,
		'yescryptR8'	=> 6353,
		'yescryptR16'	=> 6333,
		'yescryptR32'	=> 6343,
		'yespower'	=> 6234,
		'yespowerIC'	=> 6235,
		'yespowerR16'	=> 6236,
		'yespowerRES'	=> 6237,
		'yespowerSUGAR'	=> 6238,
		'yespowerURX'	=> 6239,
		'yespowerIOTS'	=> 6240,
		'yespowerLTNCG'	=> 6241,
		'yespowerLITB'	=> 6242,
		'yespowerTIDE'	=> 6243,
		'yespowerMGPC'	=> 6244,
		'yespowerARWN'	=> 6245,
		'power2b'	=> 7445,
		'bastion'	=> 6433,
		'hsr'		=> 7433,
		'phi'		=> 8333,
		'phi2'		=> 8332,
		'phi5'		=> 8334,
		'0x10'		=> 8335,
		'pipe'		=> 9393,
		'polytimos'	=> 8463,
		'skunk'		=> 8433,
		'tribus'	=> 8533,
	    'a5a'   	=> 8633,
		'minotaur'	=> 7018,
		'minotaurx'	=> 7019,
		'megabtx'	=> 7066,
		'megamec'	=> 7067,
		'mike'		=> 7079,
		
		'astralhash'   	=> 8640,
		'globalhash'   	=> 8650,
		'jeonghash'   	=> 8660,
		'padihash'   	=> 8670,
		'pawelhash'   	=> 8680,
		
	);

	global $configCustomPorts;
	if(isset($configCustomPorts[$algo]))
		return $configCustomPorts[$algo];

	if(!isset($a[$algo]))
		return 3033;

	return $a[$algo];
}

////////////////////////////////////////////////////////////////////////

function yaamp_fee($algo)
{
	$fee = controller()->memcache->get("yaamp_fee-$algo");
	if($fee && is_numeric($fee)) return (float) $fee;

/*	$norm = yaamp_get_algo_norm($algo);
	if($norm == 0) $norm = 1;

	$hashrate = getdbosql('db_hashrate', "algo=:algo order by time desc", array(':algo'=>$algo));
	if(!$hashrate || !$hashrate->difficulty) return 1;

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_pool_rate_coinonly-$algo",
		"select sum(difficulty) * $target / $interval / 1000 from shares where valid and time>$delay and algo=:algo and jobid=0", array(':algo'=>$algo));

//	$fee = round(log($hashrate->hashrate * $norm / 1000000 / $hashrate->difficulty + 1), 1) + YAAMP_FEES_MINING;
//	$fee = round(log($rate * $norm / 2000000 / $hashrate->difficulty + 1), 1) + YAAMP_FEES_MINING;
*/
	$fee = YAAMP_FEES_MINING;

	// local fees config
	global $configFixedPoolFees;
	if (isset($configFixedPoolFees[$algo])) {
		$fee = (float) $configFixedPoolFees[$algo];
	}

	controller()->memcache->set("yaamp_fee-$algo", $fee);
	return $fee;
}

function yaamp_fee_solo($algo)
{
	$fee_solo = controller()->memcache->get("yaamp_fee_solo-$algo");
	if($fee_solo && is_numeric($fee_solo)) return (float) $fee_solo;

	$fee_solo = YAAMP_FEES_SOLO;

	// local solo fees config
	global $configFixedPoolFeesSolo;
	if (isset($configFixedPoolFeesSolo[$algo])) {
		$fee_solo = (float) $configFixedPoolFeesSolo[$algo];
	}

	controller()->memcache->set("yaamp_fee_solo-$algo", $fee_solo);
	return $fee_solo;
}

function take_yaamp_fee($v, $algo, $percent=-1)
{
	if ($percent == -1) $percent = yaamp_fee($algo);

	return $v - ($v * $percent / 100.0);
}

function yaamp_hashrate_constant($algo=null)
{
	return pow(2, 42);		// 0x400 00000000
}

function yaamp_hashrate_step()
{
	return 300;
}

function yaamp_profitability($coin)
{
	if(!$coin->difficulty) return 0;

	$btcmhd = 20116.56761169 / $coin->difficulty * $coin->reward * $coin->price;
	if(!$coin->auxpow && $coin->rpcencoding == 'POW')
	{
		$listaux = getdbolist('db_coins', "enable and visible and auto_ready and auxpow and algo='$coin->algo'");
		foreach($listaux as $aux)
		{
			if(!$aux->difficulty) continue;

			$btcmhdaux = 20116.56761169 / $aux->difficulty * $aux->reward * $aux->price;
			$btcmhd += $btcmhdaux;
		}
	}

	$algo_unit_factor = yaamp_algo_mBTC_factor($coin->algo);
	return $btcmhd * $algo_unit_factor;
}

function yaamp_convert_amount_user($coin, $amount, $user)
{
	$refcoin = getdbo('db_coins', $user->coinid);
	$value = 0.;
	if (YAAMP_ALLOW_EXCHANGE) {
		if(!$refcoin) $refcoin = getdbosql('db_coins', "symbol='BTC'");
		if(!$refcoin || $refcoin->price <= 0) return 0;
		$value = $amount * $coin->price / $refcoin->price;
	} else if ($coin->price && $refcoin && $refcoin->price > 0.) {
		$value = $amount * $coin->price / $refcoin->price;
	} else if ($coin->id == $user->coinid) {
		$value = $amount;
	}
	return $value;
}

function yaamp_convert_earnings_user($user, $status)
{
	$refcoin = getdbo('db_coins', $user->coinid);
	$value = 0.;
	if (YAAMP_ALLOW_EXCHANGE) {
		if(!$refcoin) $refcoin = getdbosql('db_coins', "symbol='BTC'");
		if(!$refcoin || $refcoin->price <= 0) return 0;
		$value = dboscalar("SELECT sum(amount*price) FROM earnings WHERE $status AND userid={$user->id}");
		$value = $value / $refcoin->price;
	} else if ($refcoin && $refcoin->price > 0.) {
		$value = dboscalar("SELECT sum(amount*price) FROM earnings WHERE $status AND userid={$user->id}");
		$value = $value / $refcoin->price;
	} else if ($user->coinid) {
		$value = dboscalar("SELECT sum(amount) FROM earnings WHERE $status AND userid={$user->id} AND coinid=".$user->coinid);
	}
	return $value;
}

////////////////////////////////////////////////////////////////////////////////////////////

function yaamp_pool_rate($algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_pool_rate-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE valid AND time>$delay AND algo=:algo", array(':algo'=>$algo));

	return $rate;
}

function yaamp_pool_rate_bad($algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_pool_rate_bad-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE not valid AND time>$delay AND algo=:algo", array(':algo'=>$algo));

	return $rate;
}

function yaamp_pool_rate_rentable($algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_pool_rate_rentable-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE valid AND extranonce1 AND time>$delay AND algo=:algo", array(':algo'=>$algo));

	return $rate;
}

function yaamp_user_rate($userid, $algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_user_rate-$userid-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE valid AND time>$delay AND userid=$userid AND algo=:algo", array(':algo'=>$algo));

	return $rate;
}

function yaamp_user_rate_bad($userid, $algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$diff = (double) controller()->memcache->get_database_scalar("yaamp_user_diff_avg-$userid-$algo",
		"SELECT avg(difficulty) FROM shares WHERE valid AND time>$delay AND userid=$userid AND algo=:algo", array(':algo'=>$algo));

	$rate = controller()->memcache->get_database_scalar("yaamp_user_rate_bad-$userid-$algo",
		"SELECT ((count(id) * $diff) * $target / $interval / 1000) FROM shares WHERE valid!=1 AND time>$delay AND userid=$userid AND algo=:algo", array(':algo'=>$algo));

	return $rate;
}

function yaamp_worker_rate($workerid, $algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_worker_rate-$workerid-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE valid AND time>$delay AND workerid=".$workerid);

	return $rate;
}

function yaamp_worker_rate_bad($workerid, $algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$diff = (double) controller()->memcache->get_database_scalar("yaamp_worker_diff_avg-$workerid-$algo",
		"SELECT avg(difficulty) FROM shares WHERE valid AND time>$delay AND workerid=".$workerid);

	$rate = controller()->memcache->get_database_scalar("yaamp_worker_rate_bad-$workerid-$algo",
		"SELECT ((count(id) * $diff) * $target / $interval / 1000) FROM shares WHERE valid!=1 AND time>$delay AND workerid=".$workerid);

	return empty($rate)? 0: $rate;
}

function yaamp_worker_shares_bad($workerid, $algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = (int) controller()->memcache->get_database_scalar("yaamp_worker_shares_bad-$workerid-$algo",
		"SELECT count(id) FROM shares WHERE valid!=1 AND time>$delay AND workerid=".$workerid);

	return $rate;
}

function yaamp_coin_rate($coinid)
{
	$coin = getdbo('db_coins', $coinid);
	if(!$coin || !$coin->enable) return 0;

	$target = yaamp_hashrate_constant($coin->algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_coin_rate-$coinid",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE valid AND time>$delay AND coinid=$coinid");

	return $rate;
}

function yaamp_rented_rate($algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_rented_rate-$algo",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM shares WHERE time>$delay AND algo=:algo AND jobid!=0 AND valid", array(':algo'=>$algo));

	return $rate;
}

function yaamp_job_rate($jobid)
{
	$job = getdbo('db_jobs', $jobid);
	if(!$job) return 0;

	$target = yaamp_hashrate_constant($job->algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_job_rate-$jobid",
		"SELECT (sum(difficulty) * $target / $interval / 1000) FROM jobsubmits WHERE valid AND time>$delay AND jobid=".$jobid);
	return $rate;
}

function yaamp_job_rate_bad($jobid)
{
	$job = getdbo('db_jobs', $jobid);
	if(!$job) return 0;

	$target = yaamp_hashrate_constant($job->algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$diff = (double) controller()->memcache->get_database_scalar("yaamp_job_diff_avg-$jobid",
		"SELECT avg(difficulty) FROM jobsubmits WHERE valid AND time>$delay AND jobid=".$jobid);

	$rate = controller()->memcache->get_database_scalar("yaamp_job_rate_bad-$jobid",
		"SELECT ((count(id) * $diff) * $target / $interval / 1000) FROM jobsubmits WHERE valid!=1 AND time>$delay AND jobid=".$jobid);

	return $rate;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////

function yaamp_pool_rate_pow($algo=null)
{
	if(!$algo) $algo = user()->getState('yaamp-algo');

	$target = yaamp_hashrate_constant($algo);
	$interval = yaamp_hashrate_step();
	$delay = time()-$interval;

	$rate = controller()->memcache->get_database_scalar("yaamp_pool_rate_pow-$algo",
		"SELECT sum(shares.difficulty) * $target / $interval / 1000 FROM shares, coins
			WHERE shares.valid AND shares.time>$delay AND shares.algo=:algo AND
			shares.coinid=coins.id AND coins.rpcencoding='POW'", array(':algo'=>$algo));

	return $rate;
}

/////////////////////////////////////////////////////////////////////////////////////////////

function yaamp_renter_account($renter)
{
	if(YAAMP_PRODUCTION)
		return "renter-prod-$renter->id";
	else
		return "renter-dev-$renter->id";
}

/////////////////////////////////////////////////////////////////////////////////////////////
