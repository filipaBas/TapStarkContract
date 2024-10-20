#[cfg(test)]
mod tests {
    use super::{BettingContract, IBettingContractDispatcher, IBettingContractDispatcherTrait};

    use starknet::testing::{set_contract_address, set_caller_address};
    use starknet::{SyscallResultTrait, syscalls::deploy_syscall, get_contract_address};
    use starknet::contract_address_const;

    // Helper function to deploy the BettingContract
    fn deploy(initial_amount: felt) -> IBettingContractDispatcher {
        let (contract_address, _) = deploy_syscall(
            BettingContract::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![initial_amount].span(),
            false
        ).unwrap_syscall();

        IBettingContractDispatcher { contract_address }
    }

    #[test]
    fn test_deploy() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        // Verify that the contract's prize pool is initialized correctly
        assert_eq!(contract.get_prize_pool(), initial_amount);
    }

    #[test]
    fn test_get_user_points() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        // Fake user address
        let user = contract_address_const::<'user'>();
        set_caller_address(user);

        // Initially, the user's points should be zero
        assert_eq!(contract.get_user_points(user), 0);
    }

    #[test]
    fn test_transfer_prize() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        // Set the contract address as the owner (caller)
        let owner = contract_address_const::<'owner'>();
        set_caller_address(owner);

        // Transfer the prize to the owner
        contract.transfer_prize(owner);

        // Check if the prize pool is reset to 0
        assert_eq!(contract.get_prize_pool(), 0);

        // Verify that the user (owner) has 1 point after winning
        assert_eq!(contract.get_user_points(owner), 1);
    }

    #[test]
    #[should_panic]
    fn test_transfer_prize_empty_pool() {
        let initial_amount: felt = 0; // Empty prize pool
        let contract = deploy(initial_amount);

        let user = contract_address_const::<'user'>();
        set_caller_address(user);

        // This should panic because the prize pool is empty
        contract.transfer_prize(user);
    }

    #[test]
    fn test_handle_losing_bet() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        let user = contract_address_const::<'user'>();
        set_caller_address(user);

        // Handle a losing bet for the user
        contract.handle_losing_bet(user);

        // Verify that the user receives 3 points for losing
        assert_eq!(contract.get_user_points(user), 3);
    }

    #[test]
    fn test_claim_winnings() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        let user = contract_address_const::<'user'>();
        set_caller_address(user);

        // Simulate the user winning a prize
        contract.transfer_prize(user);

        // User should have the prize in their balance
        let winnings = contract.get_user_points(user);
        assert_eq!(winnings, 1); // 1 point for winning

        // User claims their Ether winnings
        contract.claim_winnings();

        // After claiming, the user's balance should be reset to 0
        assert_eq!(contract.get_user_points(user), 1); // Points remain but Ether is withdrawn
    }

    #[test]
    #[available_gas(200000)]
    fn test_deploy_gas() {
        deploy(100);
    }

    #[test]
    #[should_panic]
    fn test_claim_without_winnings() {
        let initial_amount: felt = 100;
        let contract = deploy(initial_amount);

        let user = contract_address_const::<'user'>();
        set_caller_address(user);

        // The user has not won any prize yet
        // This should panic because the user has no winnings to claim
        contract.claim_winnings();
    }
}
