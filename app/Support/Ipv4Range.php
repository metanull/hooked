<?php

namespace App\Support;

use InvalidArgumentException;

class Ipv4Range
{
    public static function toLong(string $ipv4): int
    {
        $long = ip2long($ipv4);

        if ($long === false) {
            throw new InvalidArgumentException('Invalid IPv4 address: '.$ipv4);
        }

        return $long;
    }

    public static function isValid(string $ipv4): bool
    {
        return filter_var($ipv4, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false;
    }

    public static function isValidNetmask(int $netmask): bool
    {
        return $netmask >= 0 && $netmask <= 32;
    }

    public static function toIpRange(string $ipRange, int $defaultNetMask = 32): string
    {
        if (strpos($ipRange, '/') === false) {
            $ipRange .= '/'.$defaultNetMask;
        }

        $rangeParts = explode('/', $ipRange, 2);
        $ip = $rangeParts[0];
        $netmask = (int) $rangeParts[1];

        if (! self::isValid($ip)) {
            throw new InvalidArgumentException('Invalid IP range: '.$ipRange);
        }

        if (! self::isValidNetmask($netmask)) {
            throw new InvalidArgumentException('Invalid netmask: '.$ipRange);
        }

        return $ip.'/'.$netmask;
    }

    public static function getIpFromRange(string $ipRange, int $defaultNetMask = 32): string
    {
        $rangeParts = explode('/', self::toIpRange($ipRange, $defaultNetMask), 2);

        return $rangeParts[0];
    }

    public static function getNetmaskFromRange(string $ipRange, int $defaultNetMask = 32): int
    {
        $rangeParts = explode('/', self::toIpRange($ipRange, $defaultNetMask), 2);

        return (int) $rangeParts[1];
    }

    public static function inRange(string $ipv4, string $ipRange, int $defaultNetMask = 32): bool
    {
        if (! self::isValid($ipv4)) {
            throw new InvalidArgumentException('Invalid IPv4 address: '.$ipv4);
        }

        $rangeIp = self::getIpFromRange($ipRange, $defaultNetMask);
        $rangeNetmask = self::getNetmaskFromRange($ipRange, $defaultNetMask);
        $decimalRange = self::toLong($rangeIp);
        $decimalIp = self::toLong($ipv4);
        $decimalBitMask = (2 ** (32 - $rangeNetmask)) - 1;
        $decimalNetMask = ~ $decimalBitMask;

        return ($decimalIp & $decimalNetMask) === ($decimalRange & $decimalNetMask);
    }

    /**
     * @param  array<int, string>  $ranges
     */
    public static function matchesAny(string $ipv4, array $ranges, int $defaultNetMask = 32): bool
    {
        foreach ($ranges as $range) {
            if (self::inRange($ipv4, $range, $defaultNetMask)) {
                return true;
            }
        }

        return false;
    }
}